import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart' as app_user;

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Check if Firebase is available
  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAuth? get _authOrNull {
    try {
      // Check if Firebase is initialized
      if (!isFirebaseAvailable) {
        return null;
      }
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges {
    final auth = _authOrNull;
    if (auth == null) {
      // Firebase not available -> treat as signed out
      return Stream<User?>.value(null);
    }
    return auth.authStateChanges();
  }

  // Current user
  User? get currentUser => _authOrNull?.currentUser;

  // Convert Firebase User to app User model
  app_user.User? _userFromFirebase(User? user) {
    if (user == null) return null;
    return app_user.User(
      id: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      avatarUrl: user.photoURL ?? 'assets/images/avatar.jpg',
      coursesCompleted: 0, // Will be fetched from database
      hoursLearned: 0,
      streakDays: 0,
    );
  }

  // Sign in with email and password
  Future<app_user.User?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final auth = _authOrNull;
    if (auth == null) {
      throw Exception('Authentication is not available. Firebase is not configured.');
    }
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(credential.user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<app_user.User?> signUpWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    final auth = _authOrNull;
    if (auth == null) {
      throw Exception('Authentication is not available. Firebase is not configured.');
    }
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();
      
      return _userFromFirebase(credential.user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<app_user.User?> signInWithGoogle() async {
    final auth = _authOrNull;
    if (auth == null) {
      throw Exception('Authentication is not available. Firebase is not configured.');
    }
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      return _userFromFirebase(userCredential.user);
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    final auth = _authOrNull;
    if (auth == null) {
      return;
    }
    await Future.wait([
      auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    final auth = _authOrNull;
    if (auth == null) {
      throw Exception('Authentication is not available. Firebase is not configured.');
    }
    try {
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get current app user
  app_user.User? getCurrentAppUser() {
    return _userFromFirebase(_authOrNull?.currentUser);
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
