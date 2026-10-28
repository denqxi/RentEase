import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/presentation/current_uid.dart';
import '../cubit/owner_onboarding_cubit.dart';
import 'document_upload_screen.dart';

/// Follows `ownerProfiles/{uid}` live, so the screen
/// flips to "verified" or shows "rejected" with admin reason live.
class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  Stream<OwnerProfileDoc?>? _profileStream;

  @override
  void initState() {
    super.initState();
    final uid = currentUidOrNull(context);
    if (uid == null) return;
    try {
      _profileStream = context
          .read<OwnerOnboardingCubit>()
          .watchOwnerProfile(uid);
    } catch (_) {
      // No cubit/Firebase (screenshot harness)
    }
  }

  void _addFirstProperty() {
    context.read<OwnerOnboardingCubit>().reset();
    Navigator.of(context).pushNamed(AppRouter.addProperty);
  }

  void _goToDashboard() => Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(AppRouter.landlordHome, (_) => false);

  void _resubmitDocuments() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DocumentUploadScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OwnerProfileDoc?>(
      stream: _profileStream,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final status = profile?.verificationStatus ?? 'pending';
        final reason = profile?.rejectionReason;
        final isRejected = status == 'rejected';
        final isVerified = status == 'verified';

        final (title, body) = switch (status) {
          'verified' => (
            "You're verified",
            'Your account is approved. Add your first property so compatible '
                'tenants can find you.',
          ),
          'rejected' => (
            'Verification needs revision',
            'Your documents require revision before your account can be verified. Please review the admin feedback below.',
          ),
          _ => (
            'Verification in progress',
            'We’re reviewing your documents. You’ll be notified once your '
                'account is verified.',
          ),
        };

        return Scaffold(
          backgroundColor: context.appColors.surface,
          appBar: AppBar(
            backgroundColor: context.appColors.surface,
            elevation: 0,
            leadingWidth: 56,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.appColors.fieldFill,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: context.appColors.textPrimary,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'Verification status',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
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
                            fontSize: 22,
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
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: context.appColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _TimelineStatusCard(status: status),
                        if (isRejected) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: AppColors.destructive,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Reason for rejection',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: context.appColors.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: ValueKey(reason),
                                  initialValue: (reason != null && reason.trim().isNotEmpty)
                                      ? reason.trim()
                                      : 'Please review and resubmit clear, valid copies of your verification documents.',
                                  readOnly: true,
                                  maxLines: null,
                                  minLines: 3,
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13.5,
                                    color: context.appColors.textPrimary,
                                    height: 1.45,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: context.appColors.fieldFill,
                                    contentPadding: const EdgeInsets.all(14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadii.field),
                                      borderSide: BorderSide(
                                        color: context.appColors.fieldBorder.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadii.field),
                                      borderSide: BorderSide(
                                        color: context.appColors.fieldBorder.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadii.field),
                                      borderSide: BorderSide(
                                        color: context.appColors.fieldBorder.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: isVerified
                      ? Column(
                          children: [
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
                          ],
                        )
                      : isRejected
                          ? AppPrimaryButton(
                              label: 'Resubmit documents',
                              onPressed: _resubmitDocuments,
                            )
                          : Column(
                              children: [
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
                color: AppColors.emerald500,
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
                    AppColors.emerald500,
                    AppColors.matchMedium,
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
                      color: AppColors.emerald500,
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
                          color: AppColors.redFill100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.red600,
                        ),
                      )
                    : Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppColors.warningFill,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: AppColors.amber600,
                        ),
                      )),
            title: rejected ? 'Verification needs revision' : 'Identity verification',
            subtitle: verified
                ? 'Your identity has been verified.'
                : (rejected
                    ? 'Needs revision — see feedback below.'
                    : 'Our team is reviewing your documents.'),
            connector: verified
                ? Container(
                    width: 2,
                    color: AppColors.emerald500,
                  )
                : CustomPaint(
                    size: const Size(2, 30),
                    painter: const _DashedLinePainter(
                      color: AppColors.slate300,
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
                      color: AppColors.emerald500,
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
                      color: AppColors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.slate300,
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
