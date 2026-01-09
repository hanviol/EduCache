import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_button.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/educache_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Welcome text
              Text(
                'Welcome to ${AppConstants.appName}',
                style: AppTextStyles.heading1.copyWith(fontSize: 36),
              ),

              const SizedBox(height: 12),

              Text(
                'Your personal offline learning companion. Start your journey today.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                ),
              ),

              const Spacer(flex: 2),

              // Buttons
              Column(
                children: [
                  CustomButton(
                    text: 'Log In',
                    onPressed: () {
                      Navigator.pushNamed(context, '/signin');
                    },
                    isPrimary: true,
                  ),

                  const SizedBox(height: 16),

                  // Google sign in button
                  Consumer(
                    builder: (context, ref, child) {
                      final isFirebaseAvailable =
                          ref.watch(isFirebaseAvailableProvider);
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: isFirebaseAvailable
                              ? () async {
                                  try {
                                    final authService =
                                        ref.read(authServiceProvider);
                                    final user =
                                        await authService.signInWithGoogle();
                                    if (user != null && context.mounted) {
                                      Navigator.pushReplacementNamed(
                                          context, '/home');
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Sign in failed: $e'),
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: isFirebaseAvailable
                                ? AppColors.textPrimary
                                : AppColors.textLight,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/google_logo.png',
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isFirebaseAvailable
                                    ? 'Continue with Google'
                                    : 'Firebase not configured',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to sign up
                        },
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
