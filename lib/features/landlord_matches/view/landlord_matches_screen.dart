import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../landlord_home/cubit/landlord_home_cubit.dart';
import '../../landlord_home/widgets/compatible_tenants_section.dart';

/// Matches tab: every compatible (bScore = 1) tenant across the owner's
/// available listings, unranked (alphabetical).
class LandlordMatchesScreen extends StatelessWidget {
  const LandlordMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: context.read<LandlordHomeCubit>().reloadTenants,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              Text('Matches', style: AppTextStyles.title(context)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Compatible tenants for your properties',
                style: AppTextStyles.caption(context).copyWith(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.md),
              const CompatibleTenantsSection(),
            ],
          ),
        ),
      ),
    );
  }
}
