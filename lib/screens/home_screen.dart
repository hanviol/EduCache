import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/progress_bar.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../providers/course_provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.pushNamed(context, '/courses');
        break;
      case 2:
        Navigator.pushNamed(context, '/downloads');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Consumer(
          builder: (context, ref, child) {
            final user = ref.watch(currentUserProvider);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning,',
                  style: AppTextStyles.caption.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  user?.name.split(' ').first ?? 'User',
                  style: AppTextStyles.heading4,
                ),
              ],
            );
          },
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final user = ref.watch(currentUserProvider);
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: context.borderColor),
                    image: user?.avatarUrl != null &&
                            user!.avatarUrl.startsWith('http')
                        ? DecorationImage(
                            image: NetworkImage(user.avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : const DecorationImage(
                            image: AssetImage('assets/images/avatar.jpg'),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: TextField(
                onSubmitted: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                  Navigator.pushNamed(context, '/courses');
                },
                decoration: InputDecoration(
                  hintText: 'Search for courses...',
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.textLight,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Continue Learning
            const Text('Continue Learning', style: AppTextStyles.heading4),

            const SizedBox(height: 16),

            Consumer(
              builder: (context, ref, child) {
                final inProgressAsync = ref.watch(continueLearningProvider);
                return inProgressAsync.when(
                  data: (courses) {
                    if (courses.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Center(
                          child: Text(
                            'Start a course to continue learning',
                            style: AppTextStyles.body.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_rounded,
                                        size: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
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
                                          Text(
                                            '${(course.progress * 100).toStringAsFixed(0)}% Complete',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                ProgressBar(
                                  progress: course.progress,
                                  height: 6,
                                  backgroundColor: context.borderColor,
                                  progressColor: AppColors.accent,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child:
                                      Consumer(builder: (context, ref, child) {
                                    return OutlinedButton(
                                      onPressed: () async {
                                        // Logic to find next incomplete lesson
                                        final db =
                                            ref.read(databaseServiceProvider);
                                        final lessons =
                                            db.getLessons(course.id);
                                        String? nextLessonId;

                                        // Find first not completed
                                        for (var lesson in lessons) {
                                          if (lesson.progress < 1.0) {
                                            nextLessonId = lesson.id;
                                            break;
                                          }
                                        }
                                        // If all completed (?), just go to course or first lesson?
                                        // If no lessons yet?

                                        if (nextLessonId != null) {
                                          Navigator.pushNamed(
                                            context,
                                            '/lesson',
                                            arguments: {
                                              'courseId': course.id,
                                              'lessonId': nextLessonId,
                                            },
                                          );
                                        } else {
                                          // Fallback to course details
                                          Navigator.pushNamed(
                                            context,
                                            '/course-detail',
                                            arguments: course.id,
                                          );
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.accent,
                                        side: const BorderSide(
                                            color: AppColors.accent),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                      ),
                                      child: const Text('Resume'),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => const SizedBox.shrink(),
                );
              },
            ),

            const SizedBox(height: 32),

            // Recommended for you
            const Text('Recommended for you', style: AppTextStyles.heading4),

            const SizedBox(height: 16),

            Consumer(
              builder: (context, ref, child) {
                final coursesAsync = ref.watch(featuredCoursesProvider);
                return coursesAsync.when(
                  data: (courses) {
                    final recommended = courses; // Provider already limits to 5
                    return Column(
                      children: recommended.map((course) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/course-detail',
                              arguments: course.id,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: course.thumbnailUrl
                                              .startsWith('http')
                                          ? NetworkImage(course.thumbnailUrl)
                                              as ImageProvider
                                          : AssetImage(course.thumbnailUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              course.title,
                                              style:
                                                  AppTextStyles.body.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            course.status == 'downloaded'
                                                ? Icons.download_done_rounded
                                                : Icons.download_rounded,
                                            size: 16,
                                            color: course.status == 'downloaded'
                                                ? AppColors.success
                                                : AppColors.textLight,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        course.description,
                                        style: AppTextStyles.caption,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 14,
                                            color: AppColors.textLight,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Academic',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => const SizedBox.shrink(),
                );
              },
            ),

            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
