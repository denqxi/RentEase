import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, outline, destructiveOutline }

/// Flexible button supporting primary, outline, and destructive-outline styles.
///
/// Can be used in two ways:
///   1. Via [variant] enum for typed style selection.
///   2. Via [color] / [isOutlined] / [isDanger] convenience params used by
///      the tenant/owner feature screens.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isSmall = false,
    this.isFullWidth = true,
    // Convenience params (used by feature screens)
    this.color,
    this.isOutlined = false,
    this.isDanger = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
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
