import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'providers/course_provider.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseService = DatabaseService();
  final notificationService = NotificationService();

  try {
    // Parallelize initialization to speed up startup
    // We use catchError on Firebase because it might fail if not configured
    await Future.wait([
      Firebase.initializeApp().catchError((e) {
        debugPrint('IA_LOG: Firebase initialization failed (ignoring): $e');
        return null as dynamic;
      }),
      databaseService.init(),
      notificationService.init(),
    ]).timeout(const Duration(seconds: 10), onTimeout: () {
      debugPrint('IA_LOG: Initialization timed out after 10s');
      return [];
    });
  } catch (e) {
    debugPrint('IA_LOG: Critical initialization error: $e');
  }

  // Global error handler to catch unhandled exceptions
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('Firebase is not configured')) {
      return const SizedBox.shrink();
    }
    return ErrorWidget(details.exception);
  };

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(databaseService),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const App(),
    ),
  );
}
