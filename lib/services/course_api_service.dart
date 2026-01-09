import '../models/course.dart';
import '../models/lesson.dart';
import 'internet_archive_service.dart';

/// Unified API service for Internet Archive content.
class CourseApiService {
  final InternetArchiveService _iaService = InternetArchiveService();

  /// Fetch courses from Internet Archive
  Future<List<Course>> fetchCourses({int limit = 50}) async {
    return await _iaService.searchCourses();
  }

  /// Fetch lessons for an Internet Archive course
  Future<List<Lesson>> fetchLessonsForCourse(String courseId) async {
    return await _iaService.fetchCourseLessons(courseId);
  }

  void dispose() {
    // No-op for IA service unless close is needed
  }
}
