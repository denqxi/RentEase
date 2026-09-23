import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// The account holder's own gender — feeds the bilateral filter's Layer 1
/// GenderMatch (`FilteringService.computePropertySideScore`). Distinct from
/// a tenant's gender-*policy* requirement of a property, which is collected
/// later in onboarding.
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

  static const _options = <String>['Female', 'Male'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Gender', style: AppTextStyles.label(context)),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            for (final option in _options) ...[
              Expanded(
                child: _GenderChip(
                  label: option,
                  isSelected: value == option,
                  onTap: () => onChanged(option),
                ),
              ),
              if (option != _options.last) SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
        if (errorText != null) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: TextStyle(
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

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSizes.fieldHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : context.appColors.fieldFill,
          borderRadius: BorderRadius.circular(AppRadii.field),
          border: Border.all(
            color: isSelected ? AppColors.accent : context.appColors.fieldBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.field(context).copyWith(
            color: isSelected ? AppColors.onInk : context.appColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
