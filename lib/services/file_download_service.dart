import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for downloading files to device storage
/// All files are stored in app's document directory
import 'package:dio_smart_retry/dio_smart_retry.dart';

class FileDownloadService {
  late final Dio _dio;

  FileDownloadService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 60), // Allow long downloads
      sendTimeout: const Duration(minutes: 60),
    ));

    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      logPrint: print, // Specify log function
      retries: 3, // Retry count
      retryDelays: const [
        // Wait time between retries
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
    ));
  }

  /// Get the base directory for course downloads
  /// Returns: /data/data/<package>/files/courses/ (Android)
  ///          ApplicationDocumentsDirectory/courses/ (iOS)
  Future<Directory> getCoursesDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final coursesDir = Directory(path.join(appDocDir.path, 'courses'));

    if (!await coursesDir.exists()) {
      await coursesDir.create(recursive: true);
    }

    return coursesDir;
  }

  /// Get directory for a specific course
  Future<Directory> getCourseDirectory(String courseId) async {
    final coursesDir = await getCoursesDirectory();
    final courseDir = Directory(path.join(coursesDir.path, courseId));

    if (!await courseDir.exists()) {
      await courseDir.create(recursive: true);
    }

    return courseDir;
  }

  /// Download a file from URL to device storage
  /// Returns the local file path
  Future<String> downloadFile({
    required String url,
    required String courseId,
    required String fileName,
    Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final courseDir = await getCourseDirectory(courseId);
      final filePath = path.join(courseDir.path, fileName);
      final file = File(filePath);

      // Check if file already exists
      if (await file.exists()) {
        return filePath;
      }

      // Download file
      await _dio.download(
        url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress?.call(received, total);
          }
        },
        deleteOnError: true,
      );

      // Verify file was downloaded
      if (!await file.exists()) {
        throw Exception('Downloaded file not found');
      }

      return filePath;
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.cancel) {
          // Cleanup handled by deleteOnError: true if download started
          // But if it was just initializing, ensure cleanup
          try {
            final courseDir = await getCourseDirectory(courseId);
            final filePath = path.join(courseDir.path, fileName);
            final file = File(filePath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (_) {}
          throw Exception('Download cancelled');
        }
        if (e.response?.statusCode == 403) {
          throw Exception('Access denied (403). Content might be restricted.');
        }
      }
      throw Exception('Failed to download file: $e');
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Delete a downloaded file
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Delete all files for a course
  Future<void> deleteCourseFiles(String courseId) async {
    try {
      final courseDir = await getCourseDirectory(courseId);
      if (await courseDir.exists()) {
        await courseDir.delete(recursive: true);
      }
    } catch (e) {
      throw Exception('Failed to delete course files: $e');
    }
  }

  /// Calculate total size of downloaded course files
  Future<double> getCourseSize(String courseId) async {
    try {
      final courseDir = await getCourseDirectory(courseId);
      if (!await courseDir.exists()) {
        return 0.0;
      }

      int totalBytes = 0;
      await for (var entity in courseDir.list(recursive: true)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }

      // Convert to MB
      return totalBytes / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }

  /// Check if a file exists locally
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}
