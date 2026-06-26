import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../shell/cubit/shell_cubit.dart';

/// Search field + dark filter button row at the top of the home screen.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({required this.onChanged, super.key});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _SearchField(onChanged: onChanged)),
        const SizedBox(width: AppSpacing.sm),
        const _FilterButton(),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: TextField(
        onChanged: onChanged,
        readOnly: true,
        onTap: () => context.read<ShellCubit>().selectTab(ShellTab.search),
        style: AppTextStyles.field,
        decoration: InputDecoration(
          hintText: 'Search homes, areas...',
          hintStyle: AppTextStyles.field.copyWith(color: AppColors.hint),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
      child: const Icon(Icons.tune_rounded, color: AppColors.onInk, size: 20),
    );
  }
}
