import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

class ProfileReviewScreen extends StatelessWidget {
  const ProfileReviewScreen({
    super.key,
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    // Mock fields that would normally come from a backend lookup by KUET email
    final fields = [
      ('Full Name', name),
      ('Email Address', email),
      ('Roll', '1907001'),
      ('Department', 'Computer Science & Engineering'),
      ('Batch', '2K19'),
      ('Blood Group', 'B+ (Positive)'),
      ('Hometown', 'Khulna'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios,
              color: AppColors.bodyText, size: 20),
        ),
        title: const Text(
          'Review Your Profile',
          style: TextStyle(
              color: AppColors.bodyText,
              fontSize: 17,
              fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.verified_user_outlined,
                  color: AppColors.primary, size: 38),
            ),
            const SizedBox(height: 16),
            const Text(
              'Information Verified',
              style: TextStyle(
                  color: AppColors.bodyText,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review the details below before completing\nyour profile setup.',
              textAlign: TextAlign.center,
              style: AppTextStyles.authSubtitle,
            ),
            const SizedBox(height: 28),
            ...fields.map((f) => _ReviewField(label: f.$1, value: f.$2)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Confirm & Continue',
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    SizedBox(width: 8),
                    Icon(Icons.check_circle_outline,
                        color: AppColors.white, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text("Something's wrong? Edit details",
                  style: AppTextStyles.authSubtitle),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ReviewField extends StatelessWidget {
  const _ReviewField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.authSubtitle),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(value,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.bodyText)),
          ),
        ],
      ),
    );
  }
}
