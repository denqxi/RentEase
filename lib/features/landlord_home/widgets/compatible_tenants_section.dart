import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/landlord_home_cubit.dart';
import '../model/tenant.dart';
import '../model/tenant_detail.dart';
import '../view/tenant_detail_screen.dart';
import 'tenant_card.dart';

/// "Compatible tenants" header with See-all link and vertical list of [TenantCard]s.
class CompatibleTenantsSection extends StatelessWidget {
  const CompatibleTenantsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tenants = context
        .select<LandlordHomeCubit, List<Tenant>>((c) => c.state.compatible);
    final cubit = context.read<LandlordHomeCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Compatible tenants',
              style: AppTextStyles.title(context).copyWith(fontSize: 18),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Text(
                'See all',
                style: AppTextStyles.link(context).copyWith(color: AppColors.accent),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: tenants.length,
          separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
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
      ],
    );
  }
}
