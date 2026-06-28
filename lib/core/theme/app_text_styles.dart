import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// App-wide text style tokens.
abstract final class AppTextStyles {
  static TextStyle heading(BuildContext context) => TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.4,
    color: context.appColors.textPrimary,
  );

  static TextStyle body(BuildContext context) => TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: context.appColors.textSecondary,
  );

  /// Label used inside primary (filled) buttons — always white.
  static const TextStyle buttonLabel = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.onInk,
  );

  static TextStyle link(BuildContext context) => TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: context.appColors.textSecondary,
  );

  static TextStyle title(BuildContext context) => TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.3,
    color: context.appColors.textPrimary,
  );

  static TextStyle label(BuildContext context) => TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: context.appColors.textPrimary,
  );

  static TextStyle field(BuildContext context) => TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: context.appColors.textPrimary,
  );

  static TextStyle caption(BuildContext context) => TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: context.appColors.textSecondary,
  );
}
