import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// The account holder's own gender — feeds the bilateral filter's Layer 1
/// GenderMatch (`FilteringService.computePropertySideScore`). Distinct from
/// a tenant's gender-*policy* requirement of a property, which is collected
/// later in onboarding.
///
/// Presented as two equal-width pill buttons ('Female' and 'Male') side by side.
class GenderSelectField extends StatelessWidget {
  const GenderSelectField({
    required this.value,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Gender', style: AppTextStyles.label(context)),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: _GenderPillButton(
                label: 'Female',
                selected: value == 'Female',
                onTap: () => onChanged('Female'),
                hasError: errorText != null && value.isEmpty,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GenderPillButton(
                label: 'Male',
                selected: value == 'Male',
                onTap: () => onChanged('Male'),
                hasError: errorText != null && value.isEmpty,
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: AppColors.destructive,
            ),
          ),
        ],
      ],
    );
  }
}

class _GenderPillButton extends StatelessWidget {
  const _GenderPillButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.hasError = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.accent
        : (hasError ? AppColors.destructive : context.appColors.fieldBorder);

    final backgroundColor = selected
        ? AppColors.accent
        : context.appColors.fieldFill;

    final textColor = selected
        ? AppColors.onInk
        : context.appColors.textPrimary;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.field),
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.field),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label,
            style: AppTextStyles.field(context).copyWith(
              color: textColor,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
