import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/custom_button.dart';
import '../widgets/progress_bar.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

import '../providers/course_provider.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseId = ModalRoute.of(context)!.settings.arguments as String;

    final courseAsync = ref.watch(courseProvider(courseId));
    final lessonsAsync = ref.watch(lessonsProvider(courseId));
    final downloadManager = ref.read(downloadManagerProvider);

    return courseAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Failed to load course: $error')),
      ),
      data: (course) {
        if (course == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Course Not Found')),
            body: const Center(child: Text('Course not found')),
          );
        }

        final downloadProgress =
            ref.watch(downloadProgressStreamProvider(courseId)).value ??
                (course.status == 'downloading' ? course.progress : 0.0);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              /// HEADER
              SliverAppBar(
                expandedHeight: 300,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: course.thumbnailUrl.startsWith('http')
                                ? NetworkImage(course.thumbnailUrl)
                                    as ImageProvider
                                : AssetImage(course.thumbnailUrl),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.6),
                              BlendMode.darken,
                            ),
                          ),
                        ),
                      ),

                      /// BACK BUTTON
                      Positioned(
                        top: 48,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      /// TITLE
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  course.subjectTag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                course.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// BODY
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// STATS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _stat(context, '${course.totalLessons}', 'Lessons'),
                            _divider(context),
                            _stat(context, '${course.downloadedLessons}',
                                'Offline'),
                            _divider(context),
                            _stat(
                              context,
                              course.status == 'downloaded'
                                  ? 'Ready'
                                  : 'Online',
                              'Status',
                              color: AppColors.success,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        /// ABOUT
                        const Text(
                          'About this course',
                          style: AppTextStyles.heading4,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 32),

                        /// DOWNLOAD BUTTON
                        if (course.status != 'downloaded' &&
                            course.status != 'downloading')
                          CustomButton(
                            text: 'Download Course',
                            isPrimary: true,
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Download started...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              try {
                                await downloadManager.downloadCourse(course);
                                ref.invalidate(courseProvider(course.id));
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Download failed: $e'),
                                  ),
                                );
                              }
                            },
                          ),

                        /// DOWNLOAD PROGRESS
                        if (course.status == 'downloading') ...[
                          const SizedBox(height: 12),
                          Text(
                            'Downloading ${(downloadProgress * 100).toStringAsFixed(0)}%',
                            style: AppTextStyles.body,
                          ),
                          const SizedBox(height: 8),
                          ProgressBar(progress: downloadProgress, height: 8),
                        ],

                        const SizedBox(height: 32),

                        /// START / RESUME BUTTON
                        lessonsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (lessons) {
                            if (lessons.isEmpty) return const SizedBox.shrink();

                            final firstLesson = lessons.first;
                            final nextIncompleteLesson = lessons.firstWhere(
                              (l) => l.progress < 1.0,
                              orElse: () => firstLesson,
                            );

                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/lesson',
                                        arguments: {
                                          'courseId': courseId,
                                          'lessonId': course.progress == 0
                                              ? firstLesson.id
                                              : nextIncompleteLesson.id,
                                        },
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          course.progress == 0
                                              ? Icons.play_circle_outline
                                              : Icons.play_arrow_rounded,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          course.progress == 0
                                              ? 'Start Course'
                                              : 'Resume Learning',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                            );
                          },
                        ),

                        /// LESSONS HEADER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Lessons',
                              style: AppTextStyles.heading4,
                            ),
                            Text(
                              '${(course.progress * 100).toStringAsFixed(0)}% Complete',
                              style: AppTextStyles.caption
                                  .copyWith(color: context.textSecondary),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// LESSONS LIST
                        lessonsAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) => Center(
                            child: Text('Failed to load lessons: $error'),
                          ),
                          data: (lessons) {
                            if (lessons.isEmpty) {
                              return const Center(
                                child: Text('No lessons available'),
                              );
                            }

                            return Column(
                              children: lessons.map((lesson) {
                                final isCompleted = lesson.progress >= 1.0;
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/lesson',
                                      arguments: {
                                        'courseId': course.id,
                                        'lessonId': lesson.id,
                                      },
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? context.surface.withOpacity(0.6)
                                          : context.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: isCompleted
                                          ? Border.all(
                                              color: context.borderColor)
                                          : Border.all(
                                              color: AppColors.primary,
                                            ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isCompleted
                                                ? AppColors.success
                                                : AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isCompleted
                                                ? Icons.check_rounded
                                                : Icons.play_arrow_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lesson.title,
                                                style:
                                                    AppTextStyles.body.copyWith(
                                                  fontWeight: isCompleted
                                                      ? FontWeight.normal
                                                      : FontWeight.bold,
                                                  decoration: isCompleted
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                                ),
                                              ),
                                              Text(
                                                lesson.type.name.toUpperCase(),
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                        color:
                                                            context.textLight),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          lesson.isDownloaded
                                              ? Icons.download_done_rounded
                                              : Icons.cloud_download_outlined,
                                          size: 20,
                                          color: lesson.isDownloaded
                                              ? AppColors.success
                                              : context.textLight,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider(BuildContext context) =>
      Container(width: 1, height: 40, color: context.borderColor);

  Widget _stat(BuildContext context, String value, String label,
          {Color? color}) =>
      Column(
        children: [
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              color: color ?? context.textPrimary,
            ),
          ),
          Text(label,
              style:
                  AppTextStyles.caption.copyWith(color: context.textSecondary)),
        ],
      );
}
