import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('About', style: AppTextStyles.heading3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
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
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'EduCache',
              style: AppTextStyles.heading2,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Version 1.0.2 (Build 450)',
              style: AppTextStyles.caption.copyWith(
                color: context.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'About',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: 12),
          Text(
            'EduCache is an offline-first educational app that allows you to download and learn from free educational courses. All content is stored locally on your device for offline access.',
            style: AppTextStyles.body.copyWith(
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Features',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('Offline-first architecture'),
          _buildFeatureItem('Download courses for offline learning'),
          _buildFeatureItem('Track your learning progress'),
          _buildFeatureItem('Free educational content'),
          const SizedBox(height: 32),
          Text(
            'Content Sources',
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: 12),
          Text(
            'Courses are sourced from free educational platforms including MIT OpenCourseWare, OpenLearn, and other open educational resources.',
            style: AppTextStyles.body.copyWith(
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
