import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/compatible_badge.dart';
import '../../inquiry/widgets/invite_button.dart';
import '../../owner/model/compatible_tenant.dart';

/// Detail view for a compatible tenant (owner perspective). Compatibility is
/// shown as a plain "Compatible" badge, never a score or percentage.
class TenantDetailScreen extends StatelessWidget {
  const TenantDetailScreen({required this.tenant, super.key});

  final CompatibleTenant tenant;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (tenant.gender.isNotEmpty) ('Gender', tenant.gender),
      if (tenant.occupation?.isNotEmpty ?? false)
        ('Occupation', tenant.occupation!),
      if (tenant.school?.isNotEmpty ?? false) ('School', tenant.school!),
      ('Max budget', '₱${tenant.maxBudget}/mo'),
    ];

    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        title: Text(
          'Tenant',
          style: AppTextStyles.title(context).copyWith(fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.accentSoft,
                child: Text(
                  tenant.initials,
                  style: AppTextStyles.title(context).copyWith(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              tenant.name,
              textAlign: TextAlign.center,
              style: AppTextStyles.title(context).copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Center(child: CompatibleBadge()),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This tenant passes all of your property rules and your '
              'property fits their requirements.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(context).copyWith(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Tenant details',
              style: AppTextStyles.title(context).copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: context.appColors.fieldFill,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              rows[i].$1,
                              style: AppTextStyles.caption(context)
                                  .copyWith(fontSize: 13),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              rows[i].$2,
                              textAlign: TextAlign.end,
                              style: AppTextStyles.label(context).copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i != rows.length - 1)
                      Divider(height: 1, color: context.appColors.fieldBorder),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      // CLAUDE.md rule 2: Invite is absent, never disabled, unless the owner
      // can really invite; an owner with several compatible properties picks
      // which one. InviteButton decides and renders nothing otherwise.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: InviteButton(
            tenantId: tenant.tenantId,
            tenantName: tenant.name,
            bScore: tenant.bScore,
          ),
        ),
      ),
    );
  }
}
