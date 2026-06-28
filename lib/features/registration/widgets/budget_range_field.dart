import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';

/// "Budget range" label + monthly value + slider.
class BudgetRangeField extends StatelessWidget {
  const BudgetRangeField({
    required this.value,
    required this.onChanged,
    this.min = 500,
    this.max = 5000,
    super.key,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Budget range',
              style:
                  AppTextStyles.label(context).copyWith(color: context.appColors.textSecondary),
            ),
            Text(
              '${CurrencyUtils.formatDollars(value)}/mo',
              style: AppTextStyles.label(context).copyWith(color: AppColors.accent),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: context.appColors.fieldFill,
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accent.withValues(alpha: 0.15),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) / 50).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
