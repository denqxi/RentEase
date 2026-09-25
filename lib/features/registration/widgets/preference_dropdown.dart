import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// A labeled dropdown for choosing a single value from [items]
/// (preferred location, gender preference, etc.).
class PreferenceDropdown extends StatelessWidget {
  const PreferenceDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    super.key,
  });

  final String label;
  final String? value;
  final String? hint;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = (value != null && items.contains(value)) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.label(context),
        ),
        SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: context.appColors.fieldFill,
            borderRadius: BorderRadius.circular(AppRadii.field),
            border: Border.all(color: context.appColors.fieldBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effectiveValue,
              hint: hint != null
                  ? Text(
                      hint!,
                      style: AppTextStyles.field(context).copyWith(
                        color: context.appColors.hint,
                      ),
                    )
                  : null,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: context.appColors.textSecondary,
              ),
              style: AppTextStyles.field(context),
              borderRadius: BorderRadius.circular(AppRadii.field),
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item, style: AppTextStyles.field(context)),
                    ),
                  )
                  .toList(),
              onChanged: (selected) {
                if (selected != null) onChanged(selected);
              },
            ),
          ),
        ),
      ],
    );
  }
}
