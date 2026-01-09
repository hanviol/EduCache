import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import '../models/course.dart';
import '../models/lesson.dart';
import '../models/download_task.dart';
import 'database_service.dart';
import 'file_download_service.dart';
import 'notification_service.dart';
import 'internet_archive_service.dart';

class DownloadManager {
  final DatabaseService _databaseService;
  final FileDownloadService _fileDownloadService;
  final InternetArchiveService _iaService;
  final NotificationService _notificationService;

  final Map<String, CancelToken> _activeDownloads = {};
  final Map<String, DownloadTask> _lessonTasks = {};
  final Map<String, DateTime> _lastUpdateTime = {};

  // Progress stream: Map<lessonId, progress>
  final _progressController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get progressStream => _progressController.stream;

  // Track overall course progress: Map<courseId, progress>
  final Map<String, double> _courseProgress = {};

  DownloadManager({
    required DatabaseService databaseService,
    required FileDownloadService fileDownloadService,
    required InternetArchiveService iaService,
    required NotificationService notificationService,
  })  : _databaseService = databaseService,
        _fileDownloadService = fileDownloadService,
        _iaService = iaService,
        _notificationService = notificationService;

  /// Start or Resume a course download
  Future<void> downloadCourse(Course course) async {
    if (_activeDownloads.containsKey(course.id)) return;

    final cancelToken = CancelToken();
    _activeDownloads[course.id] = cancelToken;

    try {
      // 1. Fetch lessons (or get from local DB if already there to support offline resume)
      List<Lesson> lessons = _databaseService.getLessons(course.id);
      if (lessons.isEmpty) {
        lessons = await _iaService.fetchCourseLessons(course.id);
        if (lessons.isEmpty) {
          throw Exception('No lessons found for course');
        }
        await _databaseService.saveLessons(course.id, lessons);
      }

      // 2. Initial UI feedback & DB Update
      await _notificationService.showDownloadNotification(
        id: course.id.hashCode,
        title: 'Starting Download',
        body: course.title,
      );

      await _databaseService.updateCourse(course.copyWith(
        status: 'downloading',
        totalLessons: lessons.length,
      ));

      // Initialize tasks
      _initializeTasks(course, lessons);

      // 3. Start background download
      // We don't await this future here so the UI unblocks immediately
      _startDownloadLoop(course, lessons, cancelToken);
    } catch (e) {
      _cleanupDownload(course.id);
      await _handleDownloadError(course, e);
      rethrow;
    }
  }

  void _initializeTasks(Course course, List<Lesson> lessons) {
    for (var lesson in lessons) {
      // preserve existing progress if any
      if (!_lessonTasks.containsKey(lesson.id)) {
        _lessonTasks[lesson.id] = DownloadTask(
          id: lesson.id,
          courseId: course.id,
          lessonId: lesson.id,
          status: lesson.isDownloaded
              ? DownloadStatus.completed
              : DownloadStatus.queued,
          progress: lesson.isDownloaded ? 1.0 : 0.0,
        );
      }
    }
    _courseProgress[course.id] = course.progress;
    _progressController.add({course.id: course.progress});
  }

  Future<void> _startDownloadLoop(
      Course course, List<Lesson> lessons, CancelToken cancelToken) async {
    int downloadedCount = 0;

    // Count already downloaded
    for (var l in lessons) {
      if (await _fileDownloadService.fileExists(l.localPath ?? '')) {
        downloadedCount++;
      }
    }

    try {
      for (var lesson in lessons) {
        if (cancelToken.isCancelled) {
          throw DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.cancel);
        }

        // Skip if already downloaded
        if (await _fileDownloadService.fileExists(lesson.localPath ?? '')) {
          // Ensure task is marked completed
          _lessonTasks[lesson.id] = _lessonTasks[lesson.id]!.copyWith(
            status: DownloadStatus.completed,
            progress: 1.0,
          );
          _updateLessonProgress(lesson.id, course.id, 1.0);
          continue;
        }

        // Start Helper
        final task = _lessonTasks[lesson.id]!.copyWith(
          status: DownloadStatus.downloading,
        );
        _lessonTasks[lesson.id] = task;
        _updateLessonProgress(lesson.id, course.id, 0.0);

        try {
          final localPath = await _fileDownloadService.downloadFile(
            url: lesson.remoteUrl,
            courseId: course.id,
            fileName:
                '${lesson.id}_${path.basename(Uri.parse(lesson.remoteUrl).path)}', // Unique filename
            cancelToken: cancelToken,
            onProgress: (received, total) {
              if (cancelToken.isCancelled) return;
              final progress = total > 0 ? received / total : 0.0;
              _updateLessonProgress(lesson.id, course.id, progress);
            },
          );

          // Success
          final updatedLesson = lesson.copyWith(
            localPath: localPath,
            isDownloaded: true,
            progress: 1.0,
          );

          await _saveLessonUpdate(course.id, updatedLesson);
          downloadedCount++;

          _lessonTasks[lesson.id] =
              task.copyWith(status: DownloadStatus.completed, progress: 1.0);
          _updateLessonProgress(lesson.id, course.id, 1.0);
        } catch (e) {
          if (cancelToken.isCancelled) rethrow;

          _lessonTasks[lesson.id] =
              task.copyWith(status: DownloadStatus.failed);
          print('IA_LOG: Lesson download failed: $e');
          // We continue to next lesson even if one fails, unless it's a cancel
        }
      }

      // Completion check
      if (!cancelToken.isCancelled) {
        final allDownloaded = downloadedCount == lessons.length;
        final status = allDownloaded ? 'downloaded' : 'available';

        // If some failed, status might still be 'available' (partial)
        // But for this requirement, let's mark as downloaded if all success

        final finalCourse = course.copyWith(
          status: status,
          downloadedLessons: downloadedCount,
          progress: allDownloaded ? 1.0 : _courseProgress[course.id],
        );
        await _databaseService.updateCourse(finalCourse);

        if (allDownloaded) {
          await _notificationService.showCompletionNotification(
            id: course.id.hashCode,
            title: 'Download Complete',
            body: '${course.title} is ready.',
          );
        } else {
          await _notificationService.showDownloadNotification(
            id: course.id.hashCode,
            title: 'Download Finished',
            body: 'Some files failed to download.',
          );
        }
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // Paused
        print('Download paused');
      } else {
        print('IA_LOG: Download loop critical error: $e');
        _notificationService.showDownloadNotification(
          id: course.id.hashCode,
          title: 'Download Error',
          body: 'An error occurred while downloading.',
        );
      }
    } finally {
      _cleanupDownload(course.id);
    }
  }

  Future<void> pauseDownload(String courseId) async {
    if (_activeDownloads.containsKey(courseId)) {
      _activeDownloads[courseId]?.cancel();
      _cleanupDownload(courseId);

      // Update DB to paused
      final course = _databaseService.getCourse(courseId);
      if (course != null) {
        await _databaseService.updateCourse(course.copyWith(status: 'paused'));
      }

      await _notificationService.cancelNotification(courseId.hashCode);

      await _notificationService.showDownloadNotification(
        id: courseId.hashCode,
        title: 'Download Paused',
        body: 'Download paused for ${course?.title ?? 'course'}',
      );
    }
  }

  // Cancel is effectively delete + stop
  Future<void> cancelDownload(String courseId) async {
    _activeDownloads[courseId]?.cancel();
    _cleanupDownload(courseId);
    await _notificationService.cancelNotification(courseId.hashCode);

    // Reset course status
    final course = _databaseService.getCourse(courseId);
    if (course != null) {
      await _databaseService.updateCourse(course.copyWith(status: 'available'));
    }
  }

  void _cleanupDownload(String courseId) {
    _activeDownloads.remove(courseId);
    _lastUpdateTime.remove(courseId);
  }

  Future<void> _handleDownloadError(Course course, Object error) async {
    await _notificationService.showDownloadNotification(
      id: course.id.hashCode,
      title: 'Download Failed',
      body: error.toString(),
    );

    await _databaseService.updateCourse(course.copyWith(status: 'failed'));
  }

  void _updateLessonProgress(
      String lessonId, String courseId, double progress) {
    // Update individual lesson task
    if (_lessonTasks.containsKey(lessonId)) {
      _lessonTasks[lessonId] =
          _lessonTasks[lessonId]!.copyWith(progress: progress);
    }
    _progressController.add({lessonId: progress});

    // Calculate and emit overall course progress
    final courseTasks =
        _lessonTasks.values.where((t) => t.courseId == courseId).toList();

    if (courseTasks.isNotEmpty) {
      final totalProgress = courseTasks.fold(0.0, (sum, t) => sum + t.progress);
      final courseProgress = totalProgress / courseTasks.length;

      _courseProgress[courseId] = courseProgress;
      _progressController.add({courseId: courseProgress});

      // Update notification
      if (_shouldUpdateNotification(courseId)) {
        _notificationService.showDownloadNotification(
          id: courseId.hashCode,
          title: 'Downloading...',
          body: '${(courseProgress * 100).toInt()}% complete',
          progress: (courseProgress * 100).toInt(),
        );
      }
    }
  }

  bool _shouldUpdateNotification(String courseId) {
    final now = DateTime.now();
    final last = _lastUpdateTime[courseId];
    if (last == null || now.difference(last).inSeconds >= 1) {
      _lastUpdateTime[courseId] = now;
      return true;
    }
    return false;
  }

  Future<void> _saveLessonUpdate(String courseId, Lesson updatedLesson) async {
    final lessons = _databaseService.getLessons(courseId);
    final newList = lessons
        .map((l) => l.id == updatedLesson.id ? updatedLesson : l)
        .toList();
    await _databaseService.saveLessons(courseId, newList);
  }

  bool isDownloading(String courseId) => _activeDownloads.containsKey(courseId);

  double getProgress(String id) {
    // Check if it's a course ID
    if (_courseProgress.containsKey(id)) {
      return _courseProgress[id]!;
    }
    // Check if it's a lesson ID
    return _lessonTasks[id]?.progress ?? 0.0;
  }

  // Backward compatibility alias if needed
  double getLessonProgress(String id) => getProgress(id);

  Future<void> deleteCourse(String courseId) async {
    await cancelDownload(courseId);
    await _fileDownloadService.deleteCourseFiles(courseId);
    final course = _databaseService.getCourse(courseId);
    if (course != null) {
      await _databaseService.updateCourse(course.copyWith(
        status: 'available',
        downloadedLessons: 0,
        progress: 0.0,
      ));
    }
  }
}
