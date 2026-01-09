import 'package:image_picker/image_picker.dart';
import '../models/user.dart' as app_user;
import '../models/lesson.dart';
import 'database_service.dart';
import 'auth_service.dart';

class ProfileService {
  final DatabaseService _databaseService;
  final AuthService _authService;

  ProfileService({
    required DatabaseService databaseService,
    required AuthService authService,
  })  : _databaseService = databaseService,
        _authService = authService;

  // Get user profile (combines Firebase Auth + local profile data)
  Future<app_user.User> getUserProfile(String userId) async {
    // Get Firebase user data
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) {
      throw Exception('User not authenticated');
    }

    // Get local profile data
    final localProfile = _databaseService.getUserProfile(userId);

    // Calculate stats from progress data
    final coursesCompleted = _calculateCoursesCompleted(userId);
    final hoursLearned = _calculateHoursLearned(userId);
    final streakDays = _calculateStreakDays(userId);

    return app_user.User(
      id: firebaseUser.uid,
      name: localProfile?['displayName'] as String? ??
          firebaseUser.displayName ??
          'User',
      email: firebaseUser.email ?? '',
      avatarUrl: localProfile?['avatarPath'] as String? ??
          firebaseUser.photoURL ??
          'assets/images/avatar.jpg',
      coursesCompleted: coursesCompleted,
      hoursLearned: hoursLearned,
      streakDays: streakDays,
    );
  }

  // Update display name
  Future<void> updateDisplayName(String userId, String newName) async {
    // Update in Firebase Auth
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      await firebaseUser.updateDisplayName(newName);
      await firebaseUser.reload();
    }

    // Save locally
    final currentProfile = _databaseService.getUserProfile(userId) ?? {};
    await _databaseService.saveUserProfile(userId, {
      ...currentProfile,
      'displayName': newName,
    });
  }

  // Update avatar (local image only)
  Future<void> updateAvatar(String userId, String imagePath) async {
    final currentProfile = _databaseService.getUserProfile(userId) ?? {};
    await _databaseService.saveUserProfile(userId, {
      ...currentProfile,
      'avatarPath': imagePath,
    });
  }

  // Pick image from gallery
  Future<String?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        return image.path;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Calculate courses completed
  int _calculateCoursesCompleted(String userId) {
    final courses = _databaseService.getCourses();
    int completed = 0;
    for (var course in courses) {
      final progress = _databaseService.getUserProgress(userId, course.id);
      if (progress >= 1.0) {
        completed++;
      }
    }
    return completed;
  }

  // Calculate hours learned (sum of duration of completed lessons)
  int _calculateHoursLearned(String userId) {
    final courses = _databaseService.getCourses();
    double totalSeconds = 0.0;

    for (var course in courses) {
      final lessons = _databaseService.getLessons(course.id);
      for (var lesson in lessons) {
        if (lesson.progress >= 1.0) {
          // If duration is 0 (pdf or unknown), assume 15 mins (900s) as fallback?
          // Or just 0. Let's assume 0 if not present, but implementation plan said "fallback".
          // Plan: "Assessment: Internet Archive metadata... fallback to an estimate".
          int duration = lesson.durationSeconds;
          if (duration == 0) {
            if (lesson.type == LessonType.video) {
              duration = 300; // 5 mins fallback
            }
            if (lesson.type == LessonType.pdf) {
              duration = 600; // 10 mins fallback
            }
          }
          totalSeconds += duration;
        }
      }
    }
    return (totalSeconds / 3600).round();
  }

  // Calculate streak days (helper)
  int _calculateStreakDays(String userId) {
    return _databaseService.getSetting<int>('streakDays_$userId') ?? 0;
  }

  // Update last activity (call when user completes a lesson)
  Future<void> updateLastActivity(String userId) async {
    final lastActivityStr =
        _databaseService.getSetting<String>('lastActivity_$userId');
    final now = DateTime.now();

    int streak = _databaseService.getSetting<int>('streakDays_$userId') ?? 0;

    if (lastActivityStr == null) {
      // First activity ever
      streak = 1;
    } else {
      final lastDate = DateTime.parse(lastActivityStr);
      final lastDateMidnight =
          DateTime(lastDate.year, lastDate.month, lastDate.day);
      final todayMidnight = DateTime(now.year, now.month, now.day);

      final difference = todayMidnight.difference(lastDateMidnight).inDays;

      if (difference == 1) {
        // Consecutive day
        streak++;
      } else if (difference > 1) {
        // Broken streak
        streak = 1;
      }
      // If difference == 0 (same day), streak remains same
    }

    await _databaseService.saveSetting('streakDays_$userId', streak);
    await _databaseService.saveSetting(
        'lastActivity_$userId', now.toIso8601String());
  }
}
