import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_button.dart';
import '../widgets/text_field_input.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
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
                'Firebase authentication is not configured. Please configure Firebase to enable sign up.';
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
                const Text('Create account', style: AppTextStyles.heading2),

                const SizedBox(height: 8),

                Text(
                  'Start your learning journey today.',
                  style: AppTextStyles.body.copyWith(
                    color: context.textSecondary,
                  ),
                ),

                const SizedBox(height: 48),

                // Name field
                TextFieldInput(
                  controller: _nameController,
                  labelText: 'Full Name',
                  hintText: 'Alex Johnson',
                  keyboardType: TextInputType.name,
                  prefixIcon: Icons.person_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Email field
                TextFieldInput(
                  controller: _emailController,
                  labelText: 'Email address',
                  hintText: 'alex@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Password field
                TextFieldInput(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Create a password',
                  obscureText: true,
                  prefixIcon: Icons.lock_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
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

                // Sign Up button
                Consumer(
                  builder: (context, ref, child) {
                    final isFirebaseAvailable =
                        ref.watch(isFirebaseAvailableProvider);
                    if (_isLoading || !isFirebaseAvailable) {
                      return CustomButton(
                        text: _isLoading
                            ? 'Creating account...'
                            : 'Firebase not configured',
                        onPressed: () {},
                        isPrimary: true,
                        isLoading: _isLoading,
                      );
                    }
                    return CustomButton(
                      text: 'Sign Up',
                      onPressed: _handleSignUp,
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

                // Google button (Placeholder logic, same as SignIn)
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
                              if (mounted) {
                                setState(() {
                                  final errorStr = e.toString();
                                  if (errorStr
                                      .contains('Firebase is not configured')) {
                                    _errorMessage =
                                        'Firebase authentication is not configured.';
                                  } else {
                                    _errorMessage = errorStr.replaceFirst(
                                        'Exception: ', '');
                                  }
                                  _isLoading = false;
                                });
                              }
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

                // Sign In link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Go back to SignIn
                        },
                        child: const Text(
                          'Sign in',
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
