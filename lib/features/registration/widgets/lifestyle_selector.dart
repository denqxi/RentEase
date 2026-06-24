import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/lifestyle_preference.dart';
import 'selectable_chip.dart';

/// Multi-select chip group for [LifestylePreference]s.
class LifestyleSelector extends StatelessWidget {
  const LifestyleSelector({
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final Set<LifestylePreference> selected;
  final ValueChanged<LifestylePreference> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Lifestyle preference',
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final preference in LifestylePreference.values)
              SelectableChip(
                label: preference.label,
                selected: selected.contains(preference),
                onTap: () => onToggle(preference),
              ),
          ],
        ),
      ],
    );
  }
}
