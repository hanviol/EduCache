import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import '../models/course.dart';
import '../models/lesson.dart';

class DatabaseService {
  static const String _coursesBoxName = 'courses';
  static const String _lessonsBoxName = 'lessons';
  static const String _userProgressBoxName = 'user_progress';
  static const String _downloadsBoxName = 'downloads';
  static const String _settingsBoxName = 'settings';
  static const String _userProfileBoxName = 'user_profile';

  late Box<Map> _coursesBox;
  late Box<Map> _lessonsBox;
  late Box<Map> _userProgressBox;
  late Box<Map> _downloadsBox;
  late Box<Map> _settingsBox;
  late Box<Map> _userProfileBox;

  Future<void> init() async {
    // Hive.initFlutter() automatically uses getApplicationDocumentsDirectory()
    // This ensures boxes are created on device storage, not host machine
    await Hive.initFlutter();

    // Register adapters if needed (for complex objects, we'll use Map serialization)
    _coursesBox = await Hive.openBox<Map>(_coursesBoxName);
    _lessonsBox = await Hive.openBox<Map>(_lessonsBoxName);
    _userProgressBox = await Hive.openBox<Map>(_userProgressBoxName);
    _downloadsBox = await Hive.openBox<Map>(_downloadsBoxName);
    _settingsBox = await Hive.openBox<Map>(_settingsBoxName);
    _userProfileBox = await Hive.openBox<Map>(_userProfileBoxName);
  }

  // Course operations
  Future<void> saveCourse(Course course) async {
    await _coursesBox.put(course.id, course.toMap());
  }

  Future<void> saveCourses(List<Course> courses) async {
    final Map<String, Map> coursesMap = {};
    for (var course in courses) {
      coursesMap[course.id] = course.toMap();
    }
    await _coursesBox.putAll(coursesMap);
  }

  List<Course> getCourses() {
    return _coursesBox.values.map((map) => Course.fromMap(map)).toList();
  }

  Course? getCourse(String courseId) {
    final map = _coursesBox.get(courseId);
    return map != null ? Course.fromMap(map) : null;
  }

  Future<void> updateCourse(Course course) async {
    await _coursesBox.put(course.id, course.toMap());
  }

  Stream<List<Course>> watchCourses() async* {
    yield getCourses();
    await for (final _ in _coursesBox.watch()) {
      yield getCourses();
    }
  }

  // Lesson operations
  Future<void> saveLessons(String courseId, List<Lesson> lessons) async {
    final Map<String, dynamic> lessonsData = {
      'courseId': courseId,
      'lessons': lessons.map((l) => l.toMap()).toList(),
    };
    await _lessonsBox.put(courseId, lessonsData);
  }

  List<Lesson> getLessons(String courseId) {
    final data = _lessonsBox.get(courseId);
    if (data == null) return [];
    final lessons = (data['lessons'] as List)
        .map((map) => Lesson.fromMap(map as Map<String, dynamic>))
        .toList();
    return lessons;
  }

  // User progress operations
  Future<void> saveUserProgress(
      String userId, String courseId, double progress) async {
    final key = '$userId-$courseId';
    await _userProgressBox.put(key, {
      'progress': progress,
      'lastUpdated': DateTime.now().toIso8601String()
    });
  }

  double getUserProgress(String userId, String courseId) {
    final key = '$userId-$courseId';
    final data = _userProgressBox.get(key);
    return data?['progress'] ?? 0.0;
  }

  // Download status operations
  Future<void> saveDownloadStatus(String courseId, String status,
      {double? progress}) async {
    await _downloadsBox.put(courseId, {
      'status': status,
      'progress': progress ?? 0.0,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic>? getDownloadStatus(String courseId) {
    return _downloadsBox.get(courseId)?.cast<String, dynamic>();
  }

  Future<void> clearDownloadStatus(String courseId) async {
    await _downloadsBox.delete(courseId);
  }

  // Settings operations
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(
        key, {'value': value, 'updatedAt': DateTime.now().toIso8601String()});
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    final data = _settingsBox.get(key);
    if (data == null) return defaultValue;
    return data['value'] as T?;
  }

  Future<void> clearSetting(String key) async {
    await _settingsBox.delete(key);
  }

  // User profile operations (local profile data, separate from Firebase Auth)
  Future<void> saveUserProfile(
      String userId, Map<String, dynamic> profile) async {
    await _userProfileBox.put(userId, {
      ...profile,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic>? getUserProfile(String userId) {
    return _userProfileBox.get(userId)?.cast<String, dynamic>();
  }

  Future<void> clearUserProfile(String userId) async {
    await _userProfileBox.delete(userId);
  }

  // Clear all data (for logout)
  Future<void> clearAll() async {
    await _coursesBox.clear();
    await _lessonsBox.clear();
    await _userProgressBox.clear();
    await _downloadsBox.clear();
    // Note: settings and user_profile are kept on logout
  }

  // Clear user-specific data (for logout)
  Future<void> clearUserData(String userId) async {
    // Clear user progress
    final keysToDelete = <String>[];
    for (var key in _userProgressBox.keys) {
      if (key.toString().startsWith('$userId-')) {
        keysToDelete.add(key.toString());
      }
    }
    for (var key in keysToDelete) {
      await _userProgressBox.delete(key);
    }
    await clearUserProfile(userId);
  }
}
