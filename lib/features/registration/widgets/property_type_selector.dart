import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/property_type.dart';
import 'selectable_chip.dart';

/// Single-select chip group for choosing a [PropertyType].
class PropertyTypeSelector extends StatelessWidget {
  const PropertyTypeSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PropertyType value;
  final ValueChanged<PropertyType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Property type',
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final type in PropertyType.values)
              SelectableChip(
                label: type.label,
                selected: type == value,
                onTap: () => onChanged(type),
              ),
          ],
        ),
      ],
    );
  }
}
