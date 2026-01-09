import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/progress_bar.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../providers/course_provider.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/courses');
        break;
      case 2:
        // Already on downloads
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // We strictly use local DB stream for downloads page to ensure real-time updates
    final coursesAsync = ref.watch(localCoursesProvider);
    final downloadManager = ref.read(downloadManagerProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Downloads', style: AppTextStyles.heading3),
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
                decoration: BoxDecoration(
                  color: context.surface,
                  border: Border(
                    bottom: BorderSide(color: context.borderColor, width: 1),
                  ),
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
                    ProgressBar(
                      progress:
                          totalDownloadedLessons > 0 ? 0.5 : 0.0, // Placeholder
                      height: 8,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Courses', style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Downloaded courses list
              Expanded(
                child: downloadedCourses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.download_rounded,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No downloaded courses',
                              style: AppTextStyles.body.copyWith(
                                color: context.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/courses');
                              },
                              child: const Text('Browse Courses'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: downloadedCourses.length,
                        itemBuilder: (context, index) {
                          final course = downloadedCourses[index];
                          final isDownloading = course.status == 'downloading';

                          final downloadProgressAsync = ref
                              .watch(downloadProgressStreamProvider(course.id));
                          final downloadProgress =
                              downloadProgressAsync.value ??
                                  (isDownloading ? course.progress : 0.0);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/course-detail',
                                  arguments: course.id,
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                      image:
                                          course.thumbnailUrl.startsWith('http')
                                              ? null
                                              : DecorationImage(
                                                  image: AssetImage(
                                                      course.thumbnailUrl),
                                                  fit: BoxFit.cover,
                                                ),
                                    ),
                                    child:
                                        course.thumbnailUrl.startsWith('http')
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
                                        ),
                                        if (isDownloading)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Text(
                                                'Downloading... ${(downloadProgress * 100).toStringAsFixed(0)}%',
                                                style: AppTextStyles.caption,
                                              ),
                                              const SizedBox(height: 4),
                                              ProgressBar(
                                                progress: downloadProgress,
                                                height: 4,
                                              ),
                                            ],
                                          )
                                        else
                                          Text(
                                            '${course.downloadedLessons}/${course.totalLessons} Lessons Offline',
                                            style: AppTextStyles.caption,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isDownloading)
                                    IconButton(
                                      icon: const Icon(Icons.cancel_rounded),
                                      onPressed: () {
                                        downloadManager
                                            .cancelDownload(course.id);
                                        ref.invalidate(coursesProvider);
                                      },
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded),
                                      onPressed: () async {
                                        try {
                                          await downloadManager
                                              .deleteCourse(course.id);
                                          ref.invalidate(coursesProvider);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text('Course deleted'),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Failed to delete: $e'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load downloads',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.invalidate(coursesProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
