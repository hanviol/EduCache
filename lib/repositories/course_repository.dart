import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/course.dart';
import '../models/lesson.dart';
import '../services/internet_archive_service.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class CourseRepository {
  final InternetArchiveService _iaService;
  final DatabaseService _databaseService;
  final SettingsService _settingsService;
  final Connectivity _connectivity = Connectivity();

  CourseRepository({
    required InternetArchiveService iaService,
    required DatabaseService databaseService,
    required SettingsService settingsService,
  })  : _iaService = iaService,
        _databaseService = databaseService,
        _settingsService = settingsService;

  // Fetch courses (online first, fallback to offline)
  Future<List<Course>> getCourses() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      List<Course> courses;

      if (isOnline) {
        // Fetch from IA
        courses = await _iaService.searchCourses();

        // Merge with offline data
        final offlineCourses = _databaseService.getCourses();
        final offlineMap = {for (var c in offlineCourses) c.id: c};

        courses = courses.map((course) {
          final offlineCourse = offlineMap[course.id];
          if (offlineCourse != null) {
            return course.copyWith(
              status: offlineCourse.status,
              progress: offlineCourse.progress,
              totalLessons: offlineCourse.totalLessons,
              downloadedLessons: offlineCourse.downloadedLessons,
              lastAccessedAt: offlineCourse.lastAccessedAt,
            );
          }
          return course;
        }).toList();

        // Save to database
        await _databaseService.saveCourses(courses);
      } else {
        // Use offline data
        courses = _databaseService.getCourses();
      }

      return courses;
    } catch (e) {
      print('IA_LOG: Error in CourseRepository.getCourses: $e');
      return _databaseService.getCourses();
    }
  }

  // Get single course
  Future<Course?> getCourse(String courseId) async {
    try {
      final offlineCourse = _databaseService.getCourse(courseId);
      if (offlineCourse != null) return offlineCourse;

      // If not in DB, try to fetch all and find it
      final all = await getCourses();
      return all.where((c) => c.id == courseId).firstOrNull;
    } catch (e) {
      return _databaseService.getCourse(courseId);
    }
  }

  // Get lessons for a course
  Future<List<Lesson>> getLessons(String courseId) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      // Always try to get from DB first for downloaded lessons
      final dbLessons = _databaseService.getLessons(courseId);
      if (dbLessons.isNotEmpty) return dbLessons;

      if (isOnline) {
        final quality = _settingsService.getDownloadQuality();
        final lessons = await _iaService.fetchCourseLessons(courseId,
            quality: quality.name);
        if (lessons.isNotEmpty) {
          await _databaseService.saveLessons(courseId, lessons);

          // Update course totalLessons
          final course = await getCourse(courseId);
          if (course != null && course.totalLessons != lessons.length) {
            await _databaseService
                .updateCourse(course.copyWith(totalLessons: lessons.length));
          }
          return lessons;
        }
      }
      return dbLessons;
    } catch (e) {
      return _databaseService.getLessons(courseId);
    }
  }

  // Update course progress
  Future<void> updateCourseProgress(String courseId, double progress) async {
    final course = await getCourse(courseId);
    if (course != null) {
      final updatedCourse = course.copyWith(
        progress: progress,
        lastAccessedAt: DateTime.now(),
      );
      await _databaseService.updateCourse(updatedCourse);
    }
  }

  // Update course download status
  Future<void> updateCourseStatus(String courseId, String status,
      {int? downloadedLessons}) async {
    final course = await getCourse(courseId);
    if (course != null) {
      final updatedCourse = course.copyWith(
        status: status,
        downloadedLessons: downloadedLessons ?? course.downloadedLessons,
      );
      await _databaseService.updateCourse(updatedCourse);
    }
  }

  // Update last accessed time only
  Future<void> updateLastAccessed(String courseId) async {
    final course = await getCourse(courseId);
    if (course != null) {
      final updatedCourse = course.copyWith(
        lastAccessedAt: DateTime.now(),
      );
      await _databaseService.updateCourse(updatedCourse);
    }
  }

  // Update lessons for a course
  Future<void> updateLessons(String courseId, List<Lesson> lessons) async {
    await _databaseService.saveLessons(courseId, lessons);
  }

  // Update lesson completion and course progress
  Future<void> updateLessonCompletion(
      String courseId, String lessonId, bool completed) async {
    final lessons = await getLessons(courseId);
    final index = lessons.indexWhere((l) => l.id == lessonId);
    if (index != -1) {
      lessons[index] = lessons[index].copyWith(progress: completed ? 1.0 : 0.0);
      await updateLessons(courseId, lessons);

      // Recalculate course progress
      final completedCount = lessons.where((l) => l.progress >= 1.0).length;
      final progress = lessons.isEmpty ? 0.0 : completedCount / lessons.length;
      await updateCourseProgress(courseId, progress);
    }
  }
}
