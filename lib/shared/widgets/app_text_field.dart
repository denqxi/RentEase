import 'package:flutter/material.dart';
<<<<<<< Updated upstream
=======
import 'package:flutter/services.dart';
>>>>>>> Stashed changes

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

<<<<<<< Updated upstream
/// Standard text field used across all RentEase screens.
class AppTextField extends StatelessWidget {
  const AppTextField({
    this.controller,
    this.hintText,
    this.prefixText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.label,
=======
/// Reusable styled input field matching the RentEase design system.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.hintText,
    this.controller,
    this.label,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixText,
    this.prefixIcon,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.focusNode,
>>>>>>> Stashed changes
    super.key,
  });

  final TextEditingController? controller;
<<<<<<< Updated upstream
  final String? hintText;
  final String? prefixText;
=======
  final String hintText;
>>>>>>> Stashed changes
  final String? label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
<<<<<<< Updated upstream
  final Widget? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
=======
  final String? prefixText;
  final Widget? prefixIcon;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      onTap: onTap,
      onChanged: onChanged,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      style: AppTextStyles.field(context),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.field(context).copyWith(color: context.appColors.hint),
        prefixText: prefixText,
        prefixStyle: AppTextStyles.field(context).copyWith(color: context.appColors.textSecondary),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
                child: prefixIcon,
              )
            : null,
        prefixIconConstraints: prefixIcon != null
            ? const BoxConstraints(minWidth: 44, minHeight: 44)
            : null,
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: maxLines > 1 ? AppSpacing.md : 14,
        ),
        filled: true,
        fillColor: enabled ? context.appColors.fieldFill : context.appColors.fieldFill.withValues(alpha: 0.6),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: context.appColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: context.appColors.fieldBorder),
        ),
      ),
    );
  }
}

/// Labelled wrapper that renders [AppTextField] with a section label above it.
class LabelledField extends StatelessWidget {
  const LabelledField({
    required this.label,
    required this.child,
    super.key,
  });

  final String label;
  final Widget child;
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
<<<<<<< Updated upstream
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: obscureText ? 1 : maxLines,
          style: AppTextStyles.field,
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            hintStyle: AppTextStyles.field.copyWith(color: AppColors.textHint),
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            filled: true,
            fillColor: AppColors.fieldBg,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.field),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.field),
              borderSide:
                  const BorderSide(color: AppColors.primaryMid, width: 1.5),
            ),
          ),
        ),
=======
      children: [
        Text(
          label,
          style: AppTextStyles.label(context).copyWith(color: context.appColors.textSecondary),
        ),
        SizedBox(height: AppSpacing.sm),
        child,
>>>>>>> Stashed changes
      ],
    );
  }
}
