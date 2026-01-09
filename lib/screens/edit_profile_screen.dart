import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/text_field_input.dart';
import '../widgets/custom_button.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nameController.text = user.name;
      if (user.avatarUrl.startsWith('/') ||
          user.avatarUrl.contains('assets/')) {
        // Local path
        _avatarPath = user.avatarUrl;
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final profileService = ref.read(profileServiceProvider);
      final imagePath = await profileService.pickImageFromGallery();
      if (imagePath != null && mounted) {
        setState(() {
          _avatarPath = imagePath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not found');
      }

      final profileService = ref.read(profileServiceProvider);

      // Update display name
      await profileService.updateDisplayName(
          user.id, _nameController.text.trim());

      // Update avatar if changed
      if (_avatarPath != null && _avatarPath != user.avatarUrl) {
        await profileService.updateAvatar(user.id, _avatarPath!);
      }

      // Refresh profile
      ref.invalidate(userProfileProvider);
      ref.invalidate(currentUserProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Edit Profile', style: AppTextStyles.heading3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: context.borderColor, width: 2),
                        image: _avatarPath != null &&
                                File(_avatarPath!).existsSync()
                            ? DecorationImage(
                                image: FileImage(File(_avatarPath!)),
                                fit: BoxFit.cover,
                              )
                            : user?.avatarUrl != null &&
                                    user!.avatarUrl.startsWith('http')
                                ? DecorationImage(
                                    image: NetworkImage(user.avatarUrl),
                                    fit: BoxFit.cover,
                                  )
                                : const DecorationImage(
                                    image:
                                        AssetImage('assets/images/avatar.jpg'),
                                    fit: BoxFit.cover,
                                  ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Name field
              TextFieldInput(
                controller: _nameController,
                labelText: 'Display Name',
                hintText: 'Enter your name',
                prefixIcon: Icons.person_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Email (read-only)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: TextEditingController(text: user?.email ?? ''),
                    enabled: false,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: const Icon(Icons.email_rounded,
                          color: AppColors.textLight),
                      filled: true,
                      fillColor: context.surface.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Save button
              CustomButton(
                text: 'Save Changes',
                onPressed: _isLoading ? () {} : () => _saveProfile(),
                isPrimary: true,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
