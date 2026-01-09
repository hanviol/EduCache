import 'package:flutter/material.dart';

/// Extension on BuildContext to provide theme-aware color getters.
/// Use these instead of hardcoded AppColors for dark mode support.
extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Background colors
  Color get background =>
      isDarkMode ? AppColors.darkBackground : AppColors.background;
  Color get surface => isDarkMode ? AppColors.darkSurface : AppColors.surface;
  Color get cardColor => isDarkMode ? AppColors.darkCard : AppColors.card;

  // Border and divider colors
  Color get borderColor => isDarkMode ? AppColors.darkBorder : AppColors.border;
  Color get dividerColor =>
      isDarkMode ? AppColors.darkDivider : AppColors.divider;

  // Text colors
  Color get textPrimary =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textSecondary =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get textLight =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.textLight;
}

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF2F3E46);
  static const Color secondary = Color(0xFF84A98C);
  static const Color accent = Color(0xFFC9A227);

  // Background
  static const Color background = Color(0xFFF6F3EE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFF6F3EE);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF1F2933);
  static const Color darkSurface = Color(0xFF323F4B);
  static const Color darkCard = Color(0xFF3E4C59);
  static const Color darkBorder = Color(0xFF52606D);
  static const Color darkDivider = Color(0xFF52606D);
  static const Color darkTextPrimary = Color(0xFFF5F7FA);
  static const Color darkTextSecondary = Color(0xFFCBD2D9);

  // Text
  static const Color textPrimary = Color(0xFF1F2933);
  static const Color textSecondary = Color(0xFF5F6C7B);
  static const Color textLight = Color(0xFF9AA5B1);

  // UI Elements
  static const Color border = Color(0xFFE0DED8);
  static const Color divider = Color(0xFFE0DED8);
  static const Color disabled = Color(0xFFE0DED8);

  // Status
  static const Color success = Color(0xFF84A98C);
  static const Color error = Color(0xFFE05D5D);
  static const Color warning = Color(0xFFC9A227);
}
