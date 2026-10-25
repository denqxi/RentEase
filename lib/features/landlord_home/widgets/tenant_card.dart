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

  static String _formatBudget(num budget) {
    if (budget >= 1000) {
      final double inK = budget / 1000.0;
      final String s = inK.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      return '${s}k';
    }
    return budget.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final details = [
      if (tenant.occupation?.isNotEmpty ?? false) tenant.occupation!,
      if (tenant.school?.isNotEmpty ?? false) tenant.school!,
    ].join(' · ');
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
          width: 0.75,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
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
                      style: AppTextStyles.label(context).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        style: AppTextStyles.caption(context)
                            .copyWith(fontSize: 12),
                      ),
                    Text(
                      '₱${_formatBudget(tenant.maxBudget)}/mo budget',
                      style: AppTextStyles.caption(context)
                          .copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CompatibleBadge(),
                        if (tenant.tenantCi != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFC7D2FE),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'ci=${tenant.tenantCi!.toDouble().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
    ),
  );
}
}
