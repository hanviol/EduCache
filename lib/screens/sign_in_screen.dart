import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_button.dart';
import '../widgets/text_field_input.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../providers/auth_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final errorStr = e.toString();
          if (errorStr.contains('Firebase is not configured')) {
            _errorMessage =
                'Firebase authentication is not configured. The app will work in offline mode. Please configure Firebase to enable authentication.';
          } else {
            // Remove "Exception: " prefix if present
            _errorMessage = errorStr.replaceFirst('Exception: ', '');
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text('Welcome back', style: AppTextStyles.heading2),

                const SizedBox(height: 8),

                Text(
                  'Sign in to continue your progress.',
                  style: AppTextStyles.body.copyWith(
                    color: context.textSecondary,
                  ),
                ),

                const SizedBox(height: 48),

                // Email field
                TextFieldInput(
                  controller: _emailController,
                  labelText: 'Email address',
                  hintText: 'alex@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_rounded,
                ),

                const SizedBox(height: 24),

                // Password field
                TextFieldInput(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  obscureText: true,
                  prefixIcon: Icons.lock_rounded,
                  suffixIcon: TextButton(
                    onPressed: () async {
                      if (_emailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter your email address')),
                        );
                        return;
                      }

                      try {
                        final authService = ref.read(authServiceProvider);
                        await authService
                            .resetPassword(_emailController.text.trim());
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Password reset email sent')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          final errorStr = e.toString();
                          final message = errorStr
                                  .contains('Firebase is not configured')
                              ? 'Firebase authentication is not configured. Password reset is not available.'
                              : errorStr.replaceFirst('Exception: ', '');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        }
                      }
                    },
                    child: Text(
                      'Forgot?',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.red.shade900.withOpacity(0.2)
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                                color: Colors.red.shade700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Sign in button
                Consumer(
                  builder: (context, ref, child) {
                    final isFirebaseAvailable =
                        ref.watch(isFirebaseAvailableProvider);
                    if (_isLoading || !isFirebaseAvailable) {
                      return CustomButton(
                        text: _isLoading
                            ? 'Signing in...'
                            : 'Firebase not configured',
                        onPressed: () {},
                        isPrimary: true,
                        isLoading: _isLoading,
                      );
                    }
                    return CustomButton(
                      text: 'Sign In',
                      onPressed: () {
                        _handleSignIn();
                      },
                      isPrimary: true,
                      isLoading: _isLoading,
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: context.borderColor, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: context.borderColor, thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Google button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });

                            try {
                              final authService = ref.read(authServiceProvider);
                              final user = await authService.signInWithGoogle();

                              if (user != null && mounted) {
                                Navigator.pushReplacementNamed(
                                    context, '/home');
                              } else if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            } catch (e) {
                              setState(() {
                                final errorStr = e.toString();
                                if (errorStr
                                    .contains('Firebase is not configured')) {
                                  _errorMessage =
                                      'Firebase authentication is not configured. The app will work in offline mode.';
                                } else {
                                  _errorMessage =
                                      errorStr.replaceFirst('Exception: ', '');
                                }
                                _isLoading = false;
                              });
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: context.surface,
                      foregroundColor: context.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: context.borderColor),
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
                        const Text(
                          'Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Sign up link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/sign-up');
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
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
