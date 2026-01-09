import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../providers/course_provider.dart';
import '../providers/theme_provider.dart';
import '../services/settings_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsService = ref.watch(settingsServiceProvider);
    final notificationsEnabled = settingsService.getNotificationsEnabled();
    final downloadQuality = settingsService.getDownloadQuality();
    final textSize = settingsService.getTextSize();
    final themeMode = settingsService.getThemeMode();
    final language = settingsService.getLanguage();
    final storageUsed = settingsService.getStorageUsedDisplay();

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings', style: AppTextStyles.heading3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'NOTIFICATIONS',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            context: context,
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (value) async {
                await settingsService.setNotificationsEnabled(value);
                setState(() {});
              },
              activeThumbColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'DOWNLOADS',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            context: context,
            icon: Icons.download_rounded,
            title: 'Download Quality',
            trailing: Text(
              settingsService.getDownloadQualityDisplay(downloadQuality),
              style:
                  AppTextStyles.caption.copyWith(color: context.textSecondary),
            ),
            onTap: () => _showDownloadQualityDialog(settingsService),
          ),
          _buildSettingItem(
            context: context,
            icon: Icons.storage_rounded,
            title: 'Storage Management',
            subtitle: 'Used: $storageUsed',
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: context.textLight,
            ),
            onTap: () {
              Navigator.pushNamed(context, '/storage-management');
            },
          ),
          const SizedBox(height: 32),
          Text(
            'APPEARANCE',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            context: context,
            icon: Icons.dark_mode_rounded,
            title: 'Theme',
            trailing: Text(
              settingsService.getThemeModeDisplay(themeMode),
              style:
                  AppTextStyles.caption.copyWith(color: context.textSecondary),
            ),
            onTap: () => _showThemeModeDialog(settingsService),
          ),
          _buildSettingItem(
            context: context,
            icon: Icons.text_fields_rounded,
            title: 'Text Size',
            trailing: Text(
              settingsService.getTextSizeDisplay(textSize),
              style:
                  AppTextStyles.caption.copyWith(color: context.textSecondary),
            ),
            onTap: () => _showTextSizeDialog(settingsService),
          ),
          const SizedBox(height: 32),
          Text(
            'PRIVACY & SECURITY',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            context: context,
            icon: Icons.security_rounded,
            title: 'Privacy & Security',
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: context.textLight,
            ),
            onTap: () {
              Navigator.pushNamed(context, '/privacy-security');
            },
          ),
          const SizedBox(height: 32),
          Text(
            'GENERAL',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            context: context,
            icon: Icons.language_rounded,
            title: 'Language',
            trailing: Text(language,
                style: AppTextStyles.caption
                    .copyWith(color: context.textSecondary)),
            onTap: () {
              // Language selection (English only for now)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('English is the only available language')),
              );
            },
          ),
          _buildSettingItem(
            context: context,
            icon: Icons.info_rounded,
            title: 'About',
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: context.textLight,
            ),
            onTap: () {
              Navigator.pushNamed(context, '/about');
            },
          ),
          _buildSettingItem(
            context: context,
            icon: Icons.description_rounded,
            title: 'Terms & Privacy',
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: context.textLight,
            ),
            onTap: () {
              Navigator.pushNamed(context, '/terms-privacy');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: context.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style:
                  AppTextStyles.caption.copyWith(color: context.textSecondary),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showDownloadQualityDialog(SettingsService settingsService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Low (480p)'),
              leading: Radio<DownloadQuality>(
                value: DownloadQuality.low,
                groupValue: settingsService.getDownloadQuality(),
                onChanged: (value) async {
                  if (value != null) {
                    await settingsService.setDownloadQuality(value);
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Medium (720p)'),
              leading: Radio<DownloadQuality>(
                value: DownloadQuality.medium,
                groupValue: settingsService.getDownloadQuality(),
                onChanged: (value) async {
                  if (value != null) {
                    await settingsService.setDownloadQuality(value);
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('High (1080p)'),
              leading: Radio<DownloadQuality>(
                value: DownloadQuality.high,
                groupValue: settingsService.getDownloadQuality(),
                onChanged: (value) async {
                  if (value != null) {
                    await settingsService.setDownloadQuality(value);
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextSizeDialog(SettingsService settingsService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Text Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Small'),
              leading: Radio<TextSize>(
                value: TextSize.small,
                groupValue: settingsService.getTextSize(),
                onChanged: (value) async {
                  if (value != null) {
                    await settingsService.setTextSize(value);
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Medium'),
              leading: Radio<TextSize>(
                value: TextSize.medium,
                groupValue: settingsService.getTextSize(),
                onChanged: (value) async {
                  if (value != null) {
                    await settingsService.setTextSize(value);
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Large'),
              leading: Radio<TextSize>(
                value: TextSize.large,
                groupValue: settingsService.getTextSize(),
                onChanged: (value) async {
                  if (value != null) {
                    await settingsService.setTextSize(value);
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeModeDialog(SettingsService settingsService) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System'),
              leading: Radio<AppThemeMode>(
                value: AppThemeMode.system,
                groupValue: settingsService.getThemeMode(),
                onChanged: (value) async {
                  if (value != null) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.system);
                    Navigator.pop(dialogContext);
                    setState(() {});
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Light'),
              leading: Radio<AppThemeMode>(
                value: AppThemeMode.light,
                groupValue: settingsService.getThemeMode(),
                onChanged: (value) async {
                  if (value != null) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.light);
                    Navigator.pop(dialogContext);
                    setState(() {});
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Dark'),
              leading: Radio<AppThemeMode>(
                value: AppThemeMode.dark,
                groupValue: settingsService.getThemeMode(),
                onChanged: (value) async {
                  if (value != null) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.dark);
                    Navigator.pop(dialogContext);
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
