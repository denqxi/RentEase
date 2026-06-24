import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// A labeled, filled text input used across the registration form steps.
///
/// State is pushed up via [onChanged]; this widget keeps no business logic.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    required this.label,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.prefixText,
    this.obscureText = false,
    this.onToggleObscure,
    this.maxLines = 1,
    super.key,
  });

  /// Field label shown above the input.
  final String label;

  /// Placeholder text shown when empty.
  final String hint;

  /// Called with the new value on every change.
  final ValueChanged<String> onChanged;

  /// Keyboard variant for the input.
  final TextInputType? keyboardType;

  /// Optional leading text inside the field (e.g. "$").
  final String? prefixText;

  /// Whether to obscure the text (password fields).
  final bool obscureText;

  /// When provided, renders a visibility toggle icon that calls this.
  final VoidCallback? onToggleObscure;

  /// Number of lines the field grows to. Defaults to 1 (single-line).
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          minLines: maxLines > 1 ? maxLines : null,
          style: AppTextStyles.field,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.field.copyWith(color: AppColors.hint),
            prefixText: prefixText,
            prefixStyle: AppTextStyles.field.copyWith(color: AppColors.hint),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.hint,
                      size: 20,
                    ),
                  ),
            filled: true,
            fillColor: AppColors.fieldFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            enabledBorder: _border(AppColors.fieldBorder),
            focusedBorder: _border(AppColors.accent),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.field),
      borderSide: BorderSide(color: color),
    );
  }
}
