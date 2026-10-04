import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/compatible_badge.dart';
import '../../owner/model/compatible_tenant.dart';

/// Row card for one compatible tenant. Shows a plain "Compatible" badge —
/// no match percentage, Ci or rank (owner-side discovery is unranked).
class TenantCard extends StatelessWidget {
  const TenantCard({required this.tenant, this.onTap, super.key});

  final CompatibleTenant tenant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (tenant.occupation?.isNotEmpty ?? false) tenant.occupation!,
      if (tenant.school?.isNotEmpty ?? false) tenant.school!,
    ].join(' · ');
    return Material(
      color: context.appColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: context.appColors.fieldBorder, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.accentSoft,
                child: Text(
                  tenant.initials,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label(context).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context)
                            .copyWith(fontSize: 12),
                      ),
                    Text(
                      '₱${tenant.maxBudget}/mo budget',
                      style: AppTextStyles.caption(context)
                          .copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const CompatibleBadge(),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: context.appColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
