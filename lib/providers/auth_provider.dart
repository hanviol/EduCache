import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/user.dart' as app_user;
import 'course_provider.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Auth state provider
final authStateProvider = StreamProvider<app_user.User?>((ref) {
  try {
    final authService = ref.watch(authServiceProvider);
    return authService.authStateChanges
        .map((firebaseUser) {
          if (firebaseUser == null) return null;
          return app_user.User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? '',
            avatarUrl: firebaseUser.photoURL ?? 'assets/images/avatar.jpg',
            coursesCompleted: 0,
            hoursLearned: 0,
            streakDays: 0,
          );
        })
        .handleError((error, stackTrace) {
          // If Firebase is not configured, return null (signed out)
          debugPrint('Auth state error: $error');
          return null;
        });
  } catch (e) {
    // Firebase not configured - return stream with null (signed out)
    debugPrint('Auth provider error: $e');
    return Stream<app_user.User?>.value(null);
  }
});

// Current user provider (basic - from Firebase Auth)
final currentUserProvider = Provider<app_user.User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

// Profile service provider
final profileServiceProvider = Provider((ref) {
  return ProfileService(
    databaseService: ref.watch(databaseServiceProvider),
    authService: ref.watch(authServiceProvider),
  );
});

// Enhanced user profile provider (includes local profile data and stats)
final userProfileProvider = FutureProvider<app_user.User?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return null;
  
  try {
    final profileService = ref.watch(profileServiceProvider);
    return await profileService.getUserProfile(user.id);
  } catch (e) {
    // Fallback to basic user if profile service fails
    return user;
  }
});

// Firebase availability provider
final isFirebaseAvailableProvider = Provider<bool>((ref) {
  try {
    final authService = ref.watch(authServiceProvider);
    return authService.isFirebaseAvailable;
  } catch (_) {
    return false;
  }
});
