import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// App-wide text style tokens.
///
/// Never hardcode font sizes/weights inline in widgets — reference these.
abstract final class AppTextStyles {
  /// Large screen heading (e.g. onboarding titles).
  static const TextStyle heading = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  /// Supporting paragraph text below a heading.
  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  /// Label used inside primary (filled) buttons.
  static const TextStyle buttonLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.onInk,
  );

  /// Tertiary / link-style action text (e.g. "Skip").
  static const TextStyle link = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Section/step title (smaller than [heading]).
  static const TextStyle title = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  /// Field / row label.
  static const TextStyle label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Input text and hint sizing inside fields.
  static const TextStyle field = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Small 12 px secondary text for bed/bath/location details.
  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );
}
