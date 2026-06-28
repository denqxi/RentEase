import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/card_over_hero_layout.dart';

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CardOverHeroLayout(
      hero: const HeroPlaceholder(),
      cardContent: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Color(0x33F59E0B),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.access_time_rounded, color: AppColors.matchMedium, size: 32),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Verification in progress',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Our team is reviewing your documents. You\'ll be notified once approved.',
            style: AppTextStyles.body(context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl),
          _ChecklistRow(
            icon: Icons.check_circle_rounded,
            color: AppColors.matchHigh,
            label: 'Documents submitted',
            badge: null,
          ),
          SizedBox(height: AppSpacing.sm),
          _ChecklistRow(
            icon: Icons.access_time_rounded,
            color: AppColors.matchMedium,
            label: 'Identity verification',
            badge: 'In progress',
            badgeColor: AppColors.matchMedium,
          ),
          SizedBox(height: AppSpacing.sm),
          _ChecklistRow(
            icon: Icons.circle_outlined,
            color: context.appColors.indicatorInactive,
            label: 'Account activation',
            badge: 'Waiting',
            badgeColor: context.appColors.indicatorInactive,
          ),
          SizedBox(height: AppSpacing.xl),
          Text(
            'This usually takes 1â€“2 business days.',
            style: AppTextStyles.caption(context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.badge,
    this.badgeColor,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: context.appColors.textPrimary,
            ),
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor?.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
      ],
    );
  }
}
