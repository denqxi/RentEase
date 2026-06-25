import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../landlord_home/cubit/landlord_home_cubit.dart';
import '../../landlord_home/model/tenant.dart';
import '../../landlord_home/model/tenant_detail.dart';
import '../../landlord_home/view/tenant_detail_screen.dart';
import '../../landlord_home/widgets/tenant_card.dart';

/// Matches tab — all tenants sorted by fit for the landlord's property.
class LandlordMatchesScreen extends StatelessWidget {
  const LandlordMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tenants = context
        .select<LandlordHomeCubit, List<Tenant>>((c) => c.state.allByMatch);
    final cubit = context.read<LandlordHomeCubit>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Matches', style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tenants sorted by best fit for your property',
                      style: AppTextStyles.caption.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              sliver: SliverList.separated(
                itemCount: tenants.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (ctx, i) => TenantCard(
                  tenant: tenants[i],
                  onSaveToggle: () => cubit.toggleSaved(tenants[i].id),
                  onTap: () => Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          TenantDetailScreen(detail: TenantDetail.sample),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
