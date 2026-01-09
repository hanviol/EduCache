import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'course_provider.dart'; // To get settingsServiceProvider
import '../services/settings_service.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return ThemeModeNotifier(settingsService);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsService _settingsService;

  ThemeModeNotifier(this._settingsService) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final appMode = _settingsService.getThemeMode();
    state = _mapAppThemeModeToThemeMode(appMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _settingsService.setThemeMode(_mapThemeModeToAppThemeMode(mode));
  }

  ThemeMode _mapAppThemeModeToThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  AppThemeMode _mapThemeModeToAppThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return AppThemeMode.system;
      case ThemeMode.light:
        return AppThemeMode.light;
      case ThemeMode.dark:
        return AppThemeMode.dark;
    }
  }
}
