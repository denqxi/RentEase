import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/presentation/current_uid.dart';
import '../cubit/owner_onboarding_cubit.dart';

/// Follows `ownerProfiles/{uid}.verificationStatus` live, so the screen
/// flips to "verified" the moment an admin approves — no refresh needed.
class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  Stream<String>? _status;

  @override
  void initState() {
    super.initState();
    final uid = currentUidOrNull(context);
    if (uid == null) return;
    try {
      _status = context
          .read<OwnerOnboardingCubit>()
          .watchVerificationStatus(uid);
    } catch (_) {
      // No cubit/Firebase (screenshot harness) — render the static pending
      // state rather than failing.
    }
  }

  void _addFirstProperty() {
    context.read<OwnerOnboardingCubit>().reset();
    Navigator.of(context).pushNamed(AppRouter.addProperty);
  }

  void _goToDashboard() => Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(AppRouter.landlordHome, (_) => false);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _status,
      initialData: 'pending',
      builder: (context, snapshot) {
        final status = snapshot.data ?? 'pending';
        final (title, body) = switch (status) {
          'verified' => (
            "You're verified",
            'Your account is approved. Add your first property so compatible '
                'tenants can find you.',
          ),
          'rejected' => (
            'Verification not approved',
            'Our team could not verify your documents. Please contact '
                'support to resubmit.',
          ),
          _ => (
            'Verification in progress',
            "Our team is reviewing your documents. You'll be notified once "
                'approved.',
          ),
        };
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
                        Text(title, style: AppTextStyles.title(context)),
                        SizedBox(height: AppSpacing.sm),
                        Text(body, style: AppTextStyles.body(context)),
                        SizedBox(height: AppSpacing.xl),
                        _StatusCard(status: status),
                        const Spacer(),
                        if (status == 'verified') ...[
                          AppPrimaryButton(
                            label: 'Add your first property',
                            onPressed: _addFirstProperty,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Center(
                            child: TextButton(
                              onPressed: _goToDashboard,
                              child: Text(
                                'Skip for now',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          AppPrimaryButton(
                            label: 'Continue to Dashboard',
                            onPressed: _goToDashboard,
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  /// 'pending' | 'verified' | 'rejected' (anything else renders as pending).
  final String status;

  @override
  Widget build(BuildContext context) {
    final verified = status == 'verified';
    final rejected = status == 'rejected';
    final headlineColor = verified
        ? AppColors.matchHigh
        : rejected
        ? AppColors.destructive
        : AppColors.matchMedium;
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
                decoration: BoxDecoration(
                  color: headlineColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  verified
                      ? Icons.verified_rounded
                      : rejected
                      ? Icons.cancel_rounded
                      : Icons.access_time_rounded,
                  color: headlineColor,
                  size: 24,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Text(
                verified
                    ? 'Approved'
                    : rejected
                    ? 'Not approved'
                    : 'Under review',
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
          if (verified)
            const _ChecklistRow(
              icon: Icons.check_circle_rounded,
              color: AppColors.matchHigh,
              label: 'Identity verification',
            )
          else if (rejected)
            const _ChecklistRow(
              icon: Icons.cancel_rounded,
              color: AppColors.destructive,
              label: 'Identity verification',
              badge: 'Rejected',
              badgeColor: AppColors.destructive,
            )
          else
            const _ChecklistRow(
              icon: Icons.access_time_rounded,
              color: AppColors.matchMedium,
              label: 'Identity verification',
              badge: 'In progress',
              badgeColor: AppColors.matchMedium,
            ),
          SizedBox(height: AppSpacing.md),
          if (verified)
            const _ChecklistRow(
              icon: Icons.check_circle_rounded,
              color: AppColors.matchHigh,
              label: 'Account activation',
            )
          else
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
