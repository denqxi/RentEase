import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
<<<<<<< Updated upstream
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
=======
>>>>>>> Stashed changes
import '../../shell/cubit/shell_cubit.dart';

/// Full-width pill search bar on the Home screen.
/// Read-only â€” tapping navigates to the Search tab.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({this.onChanged, super.key});

  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        readOnly: true,
        onTap: () => context.read<ShellCubit>().selectTab(ShellTab.search),
        onChanged: onChanged,
<<<<<<< Updated upstream
        readOnly: true,
        onTap: () => context.read<ShellCubit>().selectTab(ShellTab.search),
        style: AppTextStyles.field,
=======
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: context.appColors.textPrimary,
        ),
>>>>>>> Stashed changes
        decoration: InputDecoration(
          hintText: 'Search boarding houses...',
          hintStyle: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.appColors.hint,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: context.appColors.textSecondary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
