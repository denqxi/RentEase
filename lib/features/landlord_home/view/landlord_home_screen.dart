import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../widgets/compatible_tenants_section.dart';
import '../widgets/landlord_header.dart';
import '../widgets/landlord_search_bar.dart';
import '../widgets/property_stats_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/landlord_home_cubit.dart';
import '../model/landlord_property.dart';

/// Home tab for the landlord — property stats card + compatible tenant list.
class LandlordHomeScreen extends StatelessWidget {
  const LandlordHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final property = context
        .select<LandlordHomeCubit, LandlordProperty>((c) => c.state.property);

    return Scaffold(
      backgroundColor: context.appColors.fieldFill,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const LandlordHeader(),
                    SizedBox(height: AppSpacing.md),
                    const LandlordSearchBar(),
                    SizedBox(height: AppSpacing.md),
                    PropertyStatsCard(property: property),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: const SliverToBoxAdapter(
                child: CompatibleTenantsSection(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }
}
