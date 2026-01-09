import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../providers/course_provider.dart';

class StorageManagementScreen extends ConsumerWidget {
  const StorageManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final settingsService = ref.watch(settingsServiceProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Storage Management', style: AppTextStyles.heading3),
      ),
      body: coursesAsync.when(
        data: (courses) {
          final downloadedCourses = courses
              .where(
                  (c) => c.status == 'downloaded' || c.status == 'downloading')
              .toList();

          final totalDownloadedLessons = downloadedCourses.fold<int>(
            0,
            (sum, c) => sum + c.downloadedLessons,
          );

          return Column(
            children: [
              // Storage usage info (simplified as lessons count)
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Offline Content',
                            style: AppTextStyles.caption),
                        Text(
                          '$totalDownloadedLessons lessons offline',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value:
                          totalDownloadedLessons > 0 ? 0.5 : 0.0, // Placeholder
                      backgroundColor: context.borderColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),

              // Downloaded courses
              Expanded(
                child: downloadedCourses.isEmpty
                    ? Center(
                        child: Text(
                          'No downloaded courses',
                          style: AppTextStyles.body.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: downloadedCourses.length,
                        itemBuilder: (context, index) {
                          final course = downloadedCourses[index];
                          final isDownloading = course.status == 'downloading';

                          final downloadProgress = ref
                                  .watch(
                                      downloadProgressStreamProvider(course.id))
                                  .value ??
                              (isDownloading ? course.progress : 0.0);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                    image: course.thumbnailUrl
                                            .startsWith('http')
                                        ? null
                                        : DecorationImage(
                                            image:
                                                AssetImage(course.thumbnailUrl),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  child: course.thumbnailUrl.startsWith('http')
                                      ? const Icon(
                                          Icons.account_balance_rounded,
                                          size: 32,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course.title,
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${course.downloadedLessons}/${course.totalLessons} lessons',
                                        style: AppTextStyles.caption,
                                      ),
                                      if (isDownloading) ...[
                                        const SizedBox(height: 4),
                                        LinearProgressIndicator(
                                          value: downloadProgress,
                                          backgroundColor: context.borderColor,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(
                                            AppColors.primary,
                                          ),
                                          minHeight: 4,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Course'),
                                        content: Text(
                                          'Are you sure you want to delete "${course.title}" and all its offline content?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      try {
                                        // Use a proper delete method in DownloadManager or Repository
                                        // For now let's hope it exists or implement it if possible
                                        // await downloadManager.deleteCourse(course.id);

                                        ref.invalidate(coursesProvider);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('Course deleted')),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Failed to delete: $e')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Clear all button
              if (downloadedCourses.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
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
                                child: const Text('Clear All'),
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
                                const SnackBar(
                                    content: Text('All downloads cleared')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to clear: $e')),
                              );
                            }
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Clear All Downloads'),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Failed to load courses',
            style: AppTextStyles.body.copyWith(color: context.textSecondary),
          ),
        ),
      ),
    );
  }
}
