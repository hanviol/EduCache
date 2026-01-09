import 'database_service.dart';

enum DownloadQuality { low, medium, high }

enum TextSize { small, medium, large }

enum AppThemeMode { system, light, dark }

class SettingsService {
  final DatabaseService _databaseService;

  SettingsService({required DatabaseService databaseService})
      : _databaseService = databaseService;

  // Notifications
  bool getNotificationsEnabled() {
    return _databaseService.getSetting<bool>('notifications_enabled',
            defaultValue: true) ??
        true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _databaseService.saveSetting('notifications_enabled', enabled);
  }

  // Download Quality
  DownloadQuality getDownloadQuality() {
    final value = _databaseService.getSetting<String>('download_quality',
        defaultValue: 'medium');
    switch (value) {
      case 'low':
        return DownloadQuality.low;
      case 'high':
        return DownloadQuality.high;
      default:
        return DownloadQuality.medium;
    }
  }

  Future<void> setDownloadQuality(DownloadQuality quality) async {
    await _databaseService.saveSetting('download_quality', quality.name);
  }

  String getDownloadQualityDisplay(DownloadQuality quality) {
    switch (quality) {
      case DownloadQuality.low:
        return 'Low (480p)';
      case DownloadQuality.medium:
        return 'Medium (720p)';
      case DownloadQuality.high:
        return 'High (1080p)';
    }
  }

  // Text Size
  TextSize getTextSize() {
    final value = _databaseService.getSetting<String>('text_size',
        defaultValue: 'medium');
    switch (value) {
      case 'small':
        return TextSize.small;
      case 'large':
        return TextSize.large;
      default:
        return TextSize.medium;
    }
  }

  Future<void> setTextSize(TextSize size) async {
    await _databaseService.saveSetting('text_size', size.name);
  }

  String getTextSizeDisplay(TextSize size) {
    switch (size) {
      case TextSize.small:
        return 'Small';
      case TextSize.medium:
        return 'Medium';
      case TextSize.large:
        return 'Large';
    }
  }

  // Theme Mode
  AppThemeMode getThemeMode() {
    final value = _databaseService.getSetting<String>('theme_mode',
        defaultValue: 'system');
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _databaseService.saveSetting('theme_mode', mode.name);
  }

  String getThemeModeDisplay(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  // Language
  String getLanguage() {
    return _databaseService.getSetting<String>('language',
            defaultValue: 'English') ??
        'English';
  }

  Future<void> setLanguage(String language) async {
    await _databaseService.saveSetting('language', language);
  }

  // Clear Downloads
  Future<void> clearAllDownloads() async {
    final courses = _databaseService.getCourses();
    for (var course in courses) {
      if (course.status == 'downloaded' || course.status == 'downloading') {
        final updatedCourse = course.copyWith(
          status: 'available',
          downloadedLessons: 0,
        );
        await _databaseService.updateCourse(updatedCourse);
        await _databaseService.clearDownloadStatus(course.id);
      }
    }
  }

  // Clear Learning Progress
  Future<void> clearLearningProgress(String userId) async {
    final courses = _databaseService.getCourses();
    for (var course in courses) {
      await _databaseService.saveUserProgress(userId, course.id, 0.0);
      final updatedCourse = course.copyWith(progress: 0.0);
      await _databaseService.updateCourse(updatedCourse);
    }
  }

  // Get Storage Used (in MB)
  double getStorageUsed() {
    // Since we no longer track fileSize in the standard Course model,
    // we return 0 for now. Real storage management would require
    // checking file sizes on disk.
    return 0.0;
  }

  // Get Storage Used Display
  String getStorageUsedDisplay() {
    return '0.0 MB';
  }
}
