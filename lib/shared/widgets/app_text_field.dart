import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

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
    super.key,
  });

  final TextEditingController? controller;
  final String hintText;
  final String? label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
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
      style: AppTextStyles.field(context).copyWith(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: AppTextStyles.field(
          context,
        ).copyWith(fontSize: 14, color: context.appColors.hint),
        prefixText: prefixText,
        prefixStyle: AppTextStyles.field(
          context,
        ).copyWith(fontSize: 14, color: context.appColors.textSecondary),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 8,
                ),
                child: prefixIcon,
              )
            : null,
        prefixIconConstraints: prefixIcon != null
            ? const BoxConstraints(minWidth: 38, minHeight: 38)
            : null,
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: maxLines > 1 ? 12 : 11,
        ),
        filled: true,
        fillColor: enabled
            ? context.appColors.fieldFill
            : context.appColors.fieldFill.withValues(alpha: 0.6),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.appColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.appColors.fieldBorder),
        ),
      ),
    );
  }
}

/// Labelled wrapper that renders [AppTextField] with a section label above it.
class LabelledField extends StatelessWidget {
  const LabelledField({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label(
            context,
          ).copyWith(
            fontSize: 13,
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
