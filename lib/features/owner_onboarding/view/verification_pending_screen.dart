import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../shared/widgets/app_button.dart';

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: RegistrationAppBar(
                onBack: () => Navigator.of(context).maybePop(),
                stepNumber: 2,
                stepCount: 2,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification in progress',
                      style: AppTextStyles.title(context),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Our team is reviewing your documents. You\'ll be notified once approved.',
                      style: AppTextStyles.body(context),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    _StatusCard(context: context),
                    const Spacer(),
                    AppPrimaryButton(
                      label: 'Continue to Dashboard',
                      onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRouter.landlordHome,
                        (_) => false,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Text(
                        'This usually takes 1–2 business days.',
                        style: AppTextStyles.caption(context),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: context.appColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0x33F59E0B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: AppColors.matchMedium,
                  size: 24,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Text(
                'Under review',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          const _ChecklistRow(
            icon: Icons.check_circle_rounded,
            color: AppColors.matchHigh,
            label: 'Documents submitted',
          ),
          SizedBox(height: AppSpacing.md),
          const _ChecklistRow(
            icon: Icons.access_time_rounded,
            color: AppColors.matchMedium,
            label: 'Identity verification',
            badge: 'In progress',
            badgeColor: AppColors.matchMedium,
          ),
          SizedBox(height: AppSpacing.md),
          _ChecklistRow(
            icon: Icons.circle_outlined,
            color: context.appColors.indicatorInactive,
            label: 'Account activation',
            badge: 'Waiting',
            badgeColor: context.appColors.indicatorInactive,
          ),
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
    this.badge,
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
