import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../cubit/landlord_home_cubit.dart';

/// Search field ("Search tenantsâ€¦") + dark filter button.
class LandlordSearchBar extends StatelessWidget {
  const LandlordSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _SearchField(onChanged: context.read<LandlordHomeCubit>().updateSearch)),
        SizedBox(width: AppSpacing.sm),
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
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search tenants...',
        hintStyle: TextStyle(
          color: context.appColors.hint,
          fontSize: 14,
          fontFamily: 'DM Sans',
        ),
        prefixIcon: Icon(Icons.search, color: context.appColors.hint, size: 20),
        filled: true,
        fillColor: context.appColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: context.appColors.ink,
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
        child: Icon(Icons.tune_rounded, color: AppColors.onInk, size: 20),
      ),
    );
  }
}
