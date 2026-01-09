import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/lesson.dart';

/// Service to load lesson content from local files or remote URLs
class LessonContentService {
  /// Load lesson content
  /// Returns content as string (for text/HTML) or file path (for media)
  Future<String> loadLessonContent(Lesson lesson) async {
    // If lesson is downloaded and has local path, load from local file
    if (lesson.isDownloaded && lesson.localPath != null) {
      try {
        final file = File(lesson.localPath!);
        if (await file.exists()) {
          // For text-based content, return file content
          if (lesson.type == LessonType.text ||
              lesson.type == LessonType.reading ||
              lesson.type == LessonType.pdf) {
            return await file.readAsString();
          }
          // For media files, return path
          return lesson.localPath!;
        }
      } catch (e) {
        // Fallback to remote if local fails
      }
    }

    // Try remote URL
    if (lesson.remoteUrl.isNotEmpty) {
      try {
        // For text/HTML content, fetch and return
        if (lesson.type == LessonType.text ||
            lesson.type == LessonType.reading) {
          final response = await http.get(Uri.parse(lesson.remoteUrl));
          if (response.statusCode == 200) {
            return response.body;
          }
        }
        // For media files, return URL
        return lesson.remoteUrl;
      } catch (e) {
        // Return error message
        return 'Failed to load content: $e';
      }
    }

    return 'No content available';
  }

  /// Check if lesson content is available offline
  bool isContentAvailableOffline(Lesson lesson) {
    if (lesson.isDownloaded && lesson.localPath != null) {
      final file = File(lesson.localPath!);
      return file.existsSync();
    }
    return false;
  }

  /// Get content type for display
  String getContentType(Lesson lesson) {
    if (lesson.localPath != null) {
      final extension = lesson.localPath!.split('.').last.toLowerCase();
      return extension;
    }

    final uri = Uri.tryParse(lesson.remoteUrl);
    if (uri != null) {
      final path = uri.path;
      if (path.contains('.')) {
        final extension = path.split('.').last.toLowerCase();
        return extension;
      }
    }

    return 'text';
  }
}
