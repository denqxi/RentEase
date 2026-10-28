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
            'We’re reviewing your documents. You’ll be notified once your '
                'account is verified.',
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
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: context.appColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          body,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: context.appColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _TimelineStatusCard(status: status),
                        const Spacer(),
                        if (status == 'verified') ...[
                          AppPrimaryButton(
                            label: 'Add your first property',
                            onPressed: _addFirstProperty,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Center(
                            child: TextButton(
                              onPressed: _goToDashboard,
                              child: const Text(
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
                          const SizedBox(height: AppSpacing.sm),
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

/// Stepper timeline card matching the attached design.
class _TimelineStatusCard extends StatelessWidget {
  const _TimelineStatusCard({required this.status});

  /// 'pending' | 'verified' | 'rejected' (anything else renders as pending).
  final String status;

  @override
  Widget build(BuildContext context) {
    final verified = status == 'verified';
    final rejected = status == 'rejected';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appColors.fieldBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.scrim.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step 1: Documents submitted (Completed)
          _TimelineRow(
            indicator: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 20,
                color: AppColors.onInk,
              ),
            ),
            title: 'Documents submitted',
            subtitle: 'Your documents have been received.',
            connector: Container(
              width: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFFF59E0B),
                  ],
                ),
              ),
            ),
          ),

          // Step 2: Identity verification (In progress or Approved/Rejected)
          _TimelineRow(
            indicator: verified
                ? Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: AppColors.onInk,
                    ),
                  )
                : (rejected
                    ? Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFFDC2626),
                        ),
                      )
                    : Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: Color(0xFFD97706),
                        ),
                      )),
            title: 'Identity verification',
            subtitle: verified
                ? 'Your identity has been verified.'
                : (rejected
                    ? 'Could not verify your documents.'
                    : 'Our team is reviewing your documents.'),
            connector: verified
                ? Container(
                    width: 2,
                    color: const Color(0xFF10B981),
                  )
                : CustomPaint(
                    size: const Size(2, 30),
                    painter: const _DashedLinePainter(
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
          ),

          // Step 3: Account activation (Waiting or Activated)
          _TimelineRow(
            isLast: true,
            indicator: verified
                ? Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: AppColors.onInk,
                    ),
                  )
                : Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 2.5,
                      ),
                    ),
                  ),
            title: 'Account activation',
            subtitle: verified
                ? 'Your account is fully activated.'
                : 'You’ll get a notification once approved.',
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.indicator,
    required this.title,
    required this.subtitle,
    this.connector,
    this.isLast = false,
  });

  final Widget indicator;
  final String title;
  final String subtitle;
  final Widget? connector;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Indicator + vertical connector
          Column(
            children: [
              indicator,
              if (!isLast && connector != null)
                Expanded(
                  child: connector!,
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Right: Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 4,
                bottom: isLast ? 0 : 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: context.appColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
