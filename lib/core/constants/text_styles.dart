import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Splash
  static const TextStyle splashTitle = TextStyle(
    color: AppColors.white,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );

  static const TextStyle splashSubtitle = TextStyle(
    color: AppColors.white,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 5,
  );

  // Auth – header
  static const TextStyle authAppTitle = TextStyle(
    color: AppColors.primary,
    fontSize: 26,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle authSubtitle = TextStyle(
    color: AppColors.subText,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.bodyText,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle fieldLabel = TextStyle(
    color: AppColors.label,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  static const TextStyle fieldHint = TextStyle(
    color: AppColors.fieldHint,
    fontSize: 15,
  );

  static const TextStyle bodySmall = TextStyle(
    color: AppColors.subText,
    fontSize: 13,
  );

  static const TextStyle linkBold = TextStyle(
    color: AppColors.primary,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle dividerLabel = TextStyle(
    color: AppColors.label,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );
}
