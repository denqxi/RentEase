import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/ci_score_pill.dart';
import '../../../shared/widgets/qualified_badge.dart';

class FindTenantsScreen extends StatelessWidget {
  const FindTenantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        title: Text(
          'Find tenants',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: context.appColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  AppChip(label: 'Female only', variant: AppChipVariant.owner, isLocked: true),
                  SizedBox(width: AppSpacing.sm),
                  AppChip(label: 'No smoking', variant: AppChipVariant.owner, isLocked: true),
                  SizedBox(width: AppSpacing.sm),
                  AppChip(label: 'No pets', variant: AppChipVariant.owner, isLocked: true),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              '${MockData.tenants.length} qualified tenants',
              style: AppTextStyles.caption(context),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: MockData.tenants.length,
              separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) {
                final t = MockData.tenants[i];
                return _TenantCard(tenant: t);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({required this.tenant});

  final Map<String, dynamic> tenant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.accentSoft,
            child: Text(
              tenant['initials'] as String,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.appColors.ink,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tenant['name'] as String,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.appColors.ink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${tenant['rank']}',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onInk,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  '${tenant['gender']} Â· ${tenant['occupation']}',
                  style: AppTextStyles.caption(context),
                ),
                Text(tenant['school'] as String, style: AppTextStyles.caption(context)),
                Text(
                  '₱${tenant['budget']}/mo budget Â· ${tenant['intendedStay']} months',
                  style: AppTextStyles.caption(context),
                ),
                SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    CiScorePill(
                      score: (tenant['ciScore'] as num).toDouble(),
                      isOwner: true,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    const QualifiedBadge(),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                if (tenant['bScore'] == 1)
                  AppButton(
                    label: 'Invite',
                    variant: AppButtonVariant.outline,
                    isSmall: true,
                    isFullWidth: false,
                    onPressed: () {},
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
