import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// A labeled photo-picker row showing an "Add" tile.
///
/// Tapping the tile is a no-op until real image-picker integration is wired up.
class PhotoPickerField extends StatelessWidget {
  const PhotoPickerField({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Photos',
          style: AppTextStyles.label(context).copyWith(color: context.appColors.textSecondary),
        ),
        SizedBox(height: AppSpacing.sm),
        const _AddTile(),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: context.appColors.fieldFill,
          borderRadius: BorderRadius.circular(AppRadii.field),
          border: Border.all(color: context.appColors.fieldBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.camera_alt_outlined,
              color: context.appColors.textSecondary,
              size: 24,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Add',
              style: AppTextStyles.label(context).copyWith(
                color: context.appColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
