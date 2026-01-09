import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/bottom_nav_bar.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedIndex = 3;

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
        Navigator.pushNamed(context, '/downloads');
        break;
      case 3:
        // Already on profile
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: Column(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
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
                    const Text('Profile', style: AppTextStyles.heading3),
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                      icon: Icon(
                        Icons.settings_rounded,
                        color: context.textLight,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/avatar.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Consumer(
                      builder: (context, ref, child) {
                        final userAsync = ref.watch(userProfileProvider);
                        return userAsync.when(
                          data: (user) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'User',
                                style: AppTextStyles.heading4
                                    .copyWith(fontSize: 20),
                              ),
                              Text(user?.email ?? '',
                                  style: AppTextStyles.caption),
                            ],
                          ),
                          loading: () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Loading...',
                                style: AppTextStyles.heading4
                                    .copyWith(fontSize: 20),
                              ),
                            ],
                          ),
                          error: (_, __) => Consumer(
                            builder: (context, ref, child) {
                              final user = ref.watch(currentUserProvider);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'User',
                                    style: AppTextStyles.heading4
                                        .copyWith(fontSize: 20),
                                  ),
                                  Text(user?.email ?? '',
                                      style: AppTextStyles.caption),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final userAsync = ref.watch(userProfileProvider);
                            return userAsync.when(
                              data: (user) => Column(
                                children: [
                                  Text(
                                    '${user?.coursesCompleted ?? 0}',
                                    style: AppTextStyles.heading3,
                                  ),
                                  Text(
                                    'COURSES',
                                    style: AppTextStyles.caption.copyWith(
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              loading: () => const Column(
                                children: [
                                  Text('0', style: AppTextStyles.heading3),
                                  Text('COURSES', style: AppTextStyles.caption),
                                ],
                              ),
                              error: (_, __) => Consumer(
                                builder: (context, ref, child) {
                                  final user = ref.watch(currentUserProvider);
                                  return Column(
                                    children: [
                                      Text(
                                        '${user?.coursesCompleted ?? 0}',
                                        style: AppTextStyles.heading3,
                                      ),
                                      Text(
                                        'COURSES',
                                        style: AppTextStyles.caption.copyWith(
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final userAsync = ref.watch(userProfileProvider);
                            return userAsync.when(
                              data: (user) => Column(
                                children: [
                                  Text(
                                    '${user?.hoursLearned ?? 0}h',
                                    style: AppTextStyles.heading3,
                                  ),
                                  Text(
                                    'LEARNED',
                                    style: AppTextStyles.caption.copyWith(
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              loading: () => const Column(
                                children: [
                                  Text('0h', style: AppTextStyles.heading3),
                                  Text('LEARNED', style: AppTextStyles.caption),
                                ],
                              ),
                              error: (_, __) => Consumer(
                                builder: (context, ref, child) {
                                  final user = ref.watch(currentUserProvider);
                                  return Column(
                                    children: [
                                      Text(
                                        '${user?.hoursLearned ?? 0}h',
                                        style: AppTextStyles.heading3,
                                      ),
                                      Text(
                                        'LEARNED',
                                        style: AppTextStyles.caption.copyWith(
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final userAsync = ref.watch(userProfileProvider);
                            return userAsync.when(
                              data: (user) => Column(
                                children: [
                                  Text(
                                    '${user?.streakDays ?? 0}',
                                    style: AppTextStyles.heading3.copyWith(
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  Text(
                                    'STREAK',
                                    style: AppTextStyles.caption.copyWith(
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              loading: () => Column(
                                children: [
                                  Text(
                                    '0',
                                    style: AppTextStyles.heading3.copyWith(
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  Text(
                                    'STREAK',
                                    style: AppTextStyles.caption.copyWith(
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              error: (_, __) => Consumer(
                                builder: (context, ref, child) {
                                  final user = ref.watch(currentUserProvider);
                                  return Column(
                                    children: [
                                      Text(
                                        '${user?.streakDays ?? 0}',
                                        style: AppTextStyles.heading3.copyWith(
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      Text(
                                        'STREAK',
                                        style: AppTextStyles.caption.copyWith(
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Account settings
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'ACCOUNT',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),

                _buildListTile(
                  context: context,
                  icon: Icons.person_rounded,
                  title: 'Edit Profile',
                  onTap: () {
                    Navigator.pushNamed(context, '/edit-profile');
                  },
                ),
                _buildListTile(
                  context: context,
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  onTap: () {},
                ),
                _buildListTile(
                  context: context,
                  icon: Icons.security_rounded,
                  title: 'Privacy & Security',
                  onTap: () {},
                ),

                const SizedBox(height: 32),

                // Logout
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: context.borderColor, width: 1),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () async {
                      try {
                        final authService = ref.read(authServiceProvider);

                        await authService.signOut();

                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/welcome',
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error signing out: $e')),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE05D5D),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout_rounded, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // App version
                Center(
                  child: Text(
                    'Version 1.0.2 (Build 450)',
                    style: AppTextStyles.caption.copyWith(
                      color: context.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
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
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: context.textLight,
        size: 24,
      ),
      onTap: onTap,
    );
  }
}
