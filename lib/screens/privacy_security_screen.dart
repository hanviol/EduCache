import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../providers/course_provider.dart';
import '../providers/auth_provider.dart';

class PrivacySecurityScreen extends ConsumerWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsService = ref.watch(settingsServiceProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Privacy & Security', style: AppTextStyles.heading3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'DATA MANAGEMENT',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildListTile(
            icon: Icons.delete_sweep_rounded,
            title: 'Clear Learning Progress',
            subtitle: 'Reset all course progress',
            onTap: () async {
              if (user == null) return;

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Learning Progress'),
                  content: const Text(
                    'Are you sure you want to clear all your learning progress? This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  await settingsService.clearLearningProgress(user.id);
                  ref.invalidate(coursesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Learning progress cleared')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to clear progress: $e')),
                    );
                  }
                }
              }
            },
          ),
          _buildListTile(
            icon: Icons.delete_sweep_rounded,
            title: 'Clear All Downloads',
            subtitle: 'Delete all downloaded courses',
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Downloads'),
                  content: const Text(
                    'Are you sure you want to delete all downloaded courses?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  await settingsService.clearAllDownloads();
                  ref.invalidate(coursesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All downloads cleared')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to clear downloads: $e')),
                    );
                  }
                }
              }
            },
          ),
          const SizedBox(height: 32),
          Text(
            'PRIVACY',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _buildListTile(
            icon: Icons.lock_rounded,
            title: 'Data Privacy',
            subtitle: 'Your data is stored locally on your device',
            onTap: null,
          ),
          _buildListTile(
            icon: Icons.cloud_off_rounded,
            title: 'Offline-First',
            subtitle: 'All data is stored locally for offline access',
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTextStyles.caption,
            )
          : null,
      trailing: onTap != null
          ? const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
              size: 24,
            )
          : null,
      onTap: onTap,
    );
  }
}
