import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Styled toggle matching RentEase design: accent track when active,
/// indicatorInactive track when off, white thumb always.
class AppToggle extends StatelessWidget {
  const AppToggle({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 28,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: context.appColors.surface,
          activeTrackColor: AppColors.accent,
          inactiveThumbColor: context.appColors.surface,
          inactiveTrackColor: context.appColors.indicatorInactive,
        ),
      ),
    );
  }
}
