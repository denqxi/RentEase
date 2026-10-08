import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.prefixStyle,
    this.alwaysShowPrefix = false,
    this.showPrefixDivider = false,
    this.obscureText = false,
    this.onToggleObscure,
    this.maxLines = 1,
    this.controller,
    this.focusNode,
    this.errorText,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    super.key,
  });

  /// Whether to permanently show the prefix text even when unfocused and empty.
  final bool alwaysShowPrefix;

  /// Whether to display a vertical divider '|' after the prefix text.
  final bool showPrefixDivider;

  /// Optional focus node for managing field focus.
  final FocusNode? focusNode;

  /// Input formatters applied to the text field.
  final List<TextInputFormatter>? inputFormatters;

  /// Keyboard capitalization behavior.
  final TextCapitalization textCapitalization;

  /// Optional prefix style override.
  final TextStyle? prefixStyle;

  /// Optional controller so callers can set the text programmatically.
  final TextEditingController? controller;

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

  /// When set, renders a red border and this message below the field.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTextStyles.label(context)),
        const SizedBox(height: 6),
        SizedBox(
          height: maxLines == 1 && errorText == null ? AppSizes.fieldHeight : null,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            maxLines: obscureText ? 1 : maxLines,
            minLines: maxLines > 1 ? maxLines : null,
            style: AppTextStyles.field(context),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: AppTextStyles.field(context).copyWith(color: context.appColors.hint),
              prefixIcon: (prefixText != null && alwaysShowPrefix)
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            prefixText!.trim(),
                            style: prefixStyle ??
                                AppTextStyles.field(context).copyWith(
                                  color: context.appColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          if (showPrefixDivider) ...[
                            const SizedBox(width: 8),
                            Text(
                              '|',
                              style: TextStyle(
                                color: context.appColors.hint,
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : null,
              prefixIconConstraints: (prefixText != null && alwaysShowPrefix)
                  ? const BoxConstraints(minWidth: 0, minHeight: 0)
                  : null,
              prefixText: (prefixText != null && !alwaysShowPrefix) ? prefixText : null,
              prefixStyle: (prefixText != null && !alwaysShowPrefix)
                  ? (prefixStyle ??
                      AppTextStyles.field(context).copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ))
                  : null,
              suffixIcon: onToggleObscure == null
                  ? null
                  : IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: onToggleObscure,
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: context.appColors.hint,
                        size: 20,
                      ),
                    ),
              suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              filled: true,
              fillColor: context.appColors.fieldFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              errorText: errorText,
              errorStyle: const TextStyle(color: AppColors.destructive, fontSize: 12),
              enabledBorder: _border(context.appColors.fieldBorder),
              focusedBorder: _border(AppColors.accent),
              errorBorder: _border(AppColors.destructive),
              focusedErrorBorder: _border(AppColors.destructive),
            ),
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
