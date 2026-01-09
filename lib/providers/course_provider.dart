import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../models/lesson.dart';
import '../repositories/course_repository.dart';
import '../services/database_service.dart';
import '../services/download_manager.dart';
import '../services/settings_service.dart';
import '../services/file_download_service.dart';
import '../services/internet_archive_service.dart';
import '../services/notification_service.dart';

// Database service provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService must be initialized in main.dart');
});

// File download service provider
final fileDownloadServiceProvider = Provider<FileDownloadService>((ref) {
  return FileDownloadService();
});

final internetArchiveServiceProvider = Provider<InternetArchiveService>((ref) {
  return InternetArchiveService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Course repository provider
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(
    iaService: ref.watch(internetArchiveServiceProvider),
    databaseService: ref.watch(databaseServiceProvider),
    settingsService: ref.watch(settingsServiceProvider),
  );
});

// Download manager provider
final downloadManagerProvider = Provider<DownloadManager>((ref) {
  return DownloadManager(
    databaseService: ref.watch(databaseServiceProvider),
    fileDownloadService: ref.watch(fileDownloadServiceProvider),
    iaService: ref.watch(internetArchiveServiceProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Local courses provider - Watches Hive DB directly for real-time updates
final localCoursesProvider = StreamProvider<List<Course>>((ref) {
  final database = ref.watch(databaseServiceProvider);
  return database.watchCourses();
});

// Courses list provider - Fetches from IA
final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  return await repository.getCourses();
});

// Filtered courses by category
final filteredCoursesProvider =
    Provider.family<AsyncValue<List<Course>>, String>((ref, category) {
  final coursesAsync =
      ref.watch(localCoursesProvider); // Use local for fast updates
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  return coursesAsync.whenData((courses) {
    return courses.where((course) {
      // 1. Filter by Category
      bool matchesCategory;
      if (category == 'All') {
        matchesCategory = true;
      } else if (category == 'Finished') {
        matchesCategory = course.progress >= 1.0;
      } else {
        matchesCategory = course.category == category;
      }

      // 2. Filter by Search
      final matchesSearch = searchQuery.isEmpty ||
          course.title.toLowerCase().contains(searchQuery) ||
          course.description.toLowerCase().contains(searchQuery);

      return matchesCategory && matchesSearch;
    }).toList();
  });
});

// In-progress courses provider
final inProgressCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final courses = await ref.watch(coursesProvider.future);
  return courses.where((c) => c.progress > 0).toList();
});

// Continue Learning provider
final continueLearningProvider = Provider<AsyncValue<List<Course>>>((ref) {
  final coursesAsync = ref.watch(localCoursesProvider);

  return coursesAsync.whenData((courses) {
    // Filter: progress > 0 and lastAccessedAt != null
    // (Optionally check progress < 1.0 if we only want IN PROGRESS, but "Continue Learning" usually includes completed for review or just unfinished.)
    // Requirement says: "A course appears IF progress > 0 AND lastAccessedAt != null"
    final started = courses
        .where((c) => c.progress > 0 && c.lastAccessedAt != null)
        .toList();

    // Sort: lastAccessedAt DESC
    started.sort((a, b) => b.lastAccessedAt!.compareTo(a.lastAccessedAt!));

    // Limit: 5
    return started.take(5).toList();
  });
});

// Featured courses provider - Returns a random subset or specific featured courses
final featuredCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final courses = await ref.watch(coursesProvider.future);
  if (courses.isEmpty) return [];
  return courses.take(5).toList();
});

// Single course provider
final courseProvider =
    FutureProvider.family<Course?, String>((ref, courseId) async {
  final repository = ref.watch(courseRepositoryProvider);
  return await repository.getCourse(courseId);
});

// Lessons provider
final lessonsProvider =
    FutureProvider.family<List<Lesson>, String>((ref, courseId) async {
  final repository = ref.watch(courseRepositoryProvider);
  return await repository.getLessons(courseId);
});

// Settings service provider
final settingsServiceProvider = Provider((ref) {
  return SettingsService(
    databaseService: ref.watch(databaseServiceProvider),
  );
});

// Download progress stream provider - updated for new manager logic
final downloadProgressStreamProvider =
    StreamProvider.family<double?, String>((ref, lessonId) async* {
  final manager = ref.watch(downloadManagerProvider);
  yield manager.getLessonProgress(lessonId);

  await for (final progressMap in manager.progressStream) {
    if (progressMap.containsKey(lessonId)) {
      yield progressMap[lessonId];
    }
  }
});
