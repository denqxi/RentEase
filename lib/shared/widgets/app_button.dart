import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

<<<<<<< Updated upstream
/// Flexible button used across the new RentEase screens.
///
/// Supports filled, outlined, danger, small, and full-width variants.
=======
enum AppButtonVariant { primary, outline, destructiveOutline }

/// Flexible button supporting primary, outline, and destructive-outline styles.
///
/// Can be used in two ways:
///   1. Via [variant] enum for typed style selection.
///   2. Via [color] / [isOutlined] / [isDanger] convenience params used by
///      the tenant/owner feature screens.
>>>>>>> Stashed changes
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
<<<<<<< Updated upstream
    this.color,
    this.isDanger = false,
    this.isOutlined = false,
    this.isSmall = false,
    this.isFullWidth = true,
=======
    this.variant = AppButtonVariant.primary,
    this.isSmall = false,
    this.isFullWidth = true,
    // Convenience params (used by feature screens)
    this.color,
    this.isOutlined = false,
    this.isDanger = false,
>>>>>>> Stashed changes
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
<<<<<<< Updated upstream
  final Color? color;
  final bool isDanger;
  final bool isOutlined;
  final bool isSmall;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        isDanger ? AppColors.redPrimary : (color ?? AppColors.ink);
    final double height = isSmall ? 36.0 : AppSizes.buttonHeight;
    final double fontSize = isSmall ? 13.0 : 16.0;
    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: isSmall ? AppSpacing.md : AppSpacing.lg,
    );

    final Widget button = isOutlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: effectiveColor,
              side: BorderSide(
                color: onPressed == null ? AppColors.disabled : effectiveColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
              minimumSize: Size(0, height),
              padding: padding,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: onPressed == null ? AppColors.disabled : effectiveColor,
              ),
            ),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  onPressed == null ? AppColors.disabled : effectiveColor,
              foregroundColor: AppColors.onInk,
              disabledBackgroundColor: AppColors.disabled,
              disabledForegroundColor: AppColors.onInk,
              elevation: 0,
              minimumSize: Size(0, height),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
              padding: padding,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: AppColors.onInk,
              ),
            ),
          );

    if (!isFullWidth) return button;
    return SizedBox(width: double.infinity, height: height, child: button);
=======
  final AppButtonVariant variant;
  final bool isSmall;
  final bool isFullWidth;

  /// When set, overrides the button's fill / border colour.
  final Color? color;

  /// When true, renders as an outlined button using [color] for the border.
  final bool isOutlined;

  /// When true, renders as a destructive outlined button.
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final height = isSmall ? 36.0 : AppSizes.buttonHeight;

    // ── Convenience-param path ───────────────────────────────────────────
    if (isDanger) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: height,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.destructive),
            backgroundColor: context.appColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.buttonLabel.copyWith(
              fontSize: isSmall ? 13 : 15,
              color: AppColors.destructive,
            ),
          ),
        ),
      );
    }

    if (isOutlined) {
      final borderColor = color ?? context.appColors.fieldBorder;
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: height,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: borderColor),
            backgroundColor: context.appColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.buttonLabel.copyWith(
              fontSize: isSmall ? 13 : 15,
              color: borderColor,
            ),
          ),
        ),
      );
    }

    if (color != null) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: height,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed != null ? color : context.appColors.indicatorInactive,
            foregroundColor: AppColors.onInk,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.buttonLabel.copyWith(
              fontSize: isSmall ? 13 : 15,
              color: onPressed != null ? AppColors.onInk : context.appColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // ── Variant enum path ────────────────────────────────────────────────
    switch (variant) {
      case AppButtonVariant.primary:
        return SizedBox(
          width: isFullWidth ? double.infinity : null,
          height: height,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: onPressed != null ? context.appColors.ink : context.appColors.indicatorInactive,
              foregroundColor: onPressed != null ? AppColors.onInk : context.appColors.textSecondary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.buttonLabel.copyWith(
                fontSize: isSmall ? 13 : 15,
                color: onPressed != null ? AppColors.onInk : context.appColors.textSecondary,
              ),
            ),
          ),
        );

      case AppButtonVariant.outline:
        return SizedBox(
          width: isFullWidth ? double.infinity : null,
          height: height,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.appColors.fieldBorder),
              backgroundColor: context.appColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.buttonLabel.copyWith(
                fontSize: isSmall ? 13 : 15,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
        );

      case AppButtonVariant.destructiveOutline:
        return SizedBox(
          width: isFullWidth ? double.infinity : null,
          height: height,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.destructive),
              backgroundColor: context.appColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.buttonLabel.copyWith(
                fontSize: isSmall ? 13 : 15,
                color: AppColors.destructive,
              ),
            ),
          ),
        );
    }
>>>>>>> Stashed changes
  }
}

/// Primary, full-width filled button used for the main call-to-action.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// Text shown inside the button.
  final String label;

  /// Tapped callback. When null, the button renders disabled.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.appColors.ink,
          foregroundColor: AppColors.onInk,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
        child: Text(label, style: AppTextStyles.buttonLabel),
      ),
    );
  }
}
