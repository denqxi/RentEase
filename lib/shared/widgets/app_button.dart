import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// Flexible button used across the new RentEase screens.
///
/// Supports filled, outlined, danger, small, and full-width variants.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.color,
    this.isDanger = false,
    this.isOutlined = false,
    this.isSmall = false,
    this.isFullWidth = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
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
          backgroundColor: AppColors.ink,
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
