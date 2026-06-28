import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// Two side-by-side number inputs for minimum and maximum age.
class AgeRangeField extends StatelessWidget {
  const AgeRangeField({
    required this.onMinChanged,
    required this.onMaxChanged,
    super.key,
  });

  final ValueChanged<String> onMinChanged;
  final ValueChanged<String> onMaxChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Preferred age range',
          style: AppTextStyles.label(context).copyWith(color: context.appColors.textSecondary),
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: _AgeInput(
                label: 'Min age',
                hint: '18',
                onChanged: onMinChanged,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: _AgeInput(
                label: 'Max age',
                hint: '45',
                onChanged: onMaxChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AgeInput extends StatelessWidget {
  const _AgeInput({
    required this.label,
    required this.hint,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTextStyles.label(context)),
        SizedBox(height: AppSpacing.sm),
        TextField(
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          style: AppTextStyles.field(context),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.field(context).copyWith(color: context.appColors.hint),
            filled: true,
            fillColor: context.appColors.fieldFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            enabledBorder: _border(context.appColors.fieldBorder),
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
