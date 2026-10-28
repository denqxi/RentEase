import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/cloudinary_config.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/presentation/current_uid.dart';
import '../../uploads/data/repositories/cloudinary_image_upload_repository.dart';
import '../../uploads/domain/entities/uploaded_image.dart';
import '../../uploads/domain/repositories/image_upload_repository.dart';
import '../../uploads/presentation/cubit/image_upload_cubit.dart';
import '../cubit/owner_onboarding_cubit.dart';

/// Step 1/2 of Owner Verification — "Verify your account".
///
/// Collects:
///   1. Government-issued ID (Front side) [Required]
///   2. Government-issued ID (Back side) [Required]
///   3. Property ownership document [Required]
///   4. Business permit (if applicable) [Optional]
class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({this.repository, super.key});

  /// Override for tests; defaults to the Cloudinary implementation.
  final ImageUploadRepository? repository;

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  late final ImageUploadCubit _uploads = ImageUploadCubit(
    repository: widget.repository ?? CloudinaryImageUploadRepository(),
    kind: ImageKind.verificationDocument,
    slotCount: CloudinaryConfig.documentCount, // 4 slots
    minRequired: CloudinaryConfig.requiredDocumentCount, // 3 required
    // Slots 0 (Front), 1 (Back), and 2 (Property Ownership) are required.
    // Slot 3 (Business Permit) is optional.
    requiredSlots: const {0, 1, 2},
  );

  bool _submitting = false;

  @override
  void dispose() {
    _uploads.close();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final uid = currentUidOrNull(context);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please sign in again.'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }
    final cubit = context.read<OwnerOnboardingCubit>();
    setState(() => _submitting = true);
    await cubit.submitForVerification(uid, documents: _uploads.state.images);
    if (!mounted) return;
    setState(() => _submitting = false);

    final state = cubit.state;
    if (state.status == OwnerOnboardingStatus.failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Could not submit. Try again.'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.verificationPending, (_) => false);
  }

  void _showFaqDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.scrim.withValues(alpha: 0.5),
      builder: (_) => const _VerificationFaqDialog(),
    );
  }

  Future<void> _handlePick(int slotIndex, PickSource source) async {
    final isCamera = source == PickSource.camera;

    if (!kIsWeb) {
      try {
        if (isCamera) {
          // Requests native Android OS system permission directly
          final status = await Permission.camera.request();
          if (status.isPermanentlyDenied) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Camera permission is denied. Please allow camera access in Settings.',
                ),
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: AppColors.matchHigh,
                  onPressed: openAppSettings,
                ),
              ),
            );
            return;
          }
          if (!status.isGranted && !status.isLimited) {
            return;
          }
        } else {
          // Requests native Android OS system permission for photos/storage
          var status = await Permission.photos.request();
          if (status.isDenied) {
            status = await Permission.storage.request();
          }
          if (status.isPermanentlyDenied) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Photos and files access is denied. Please allow access in Settings.',
                ),
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: AppColors.matchHigh,
                  onPressed: openAppSettings,
                ),
              ),
            );
            return;
          }
          if (!status.isGranted && !status.isLimited) {
            final storageStatus = await Permission.storage.status;
            final photosStatus = await Permission.photos.status;
            if (status.isDenied &&
                !storageStatus.isGranted &&
                !photosStatus.isGranted) {
              return;
            }
          }
        }
      } on MissingPluginException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please stop and restart the app ("flutter run") to link native Android permissions.',
            ),
            backgroundColor: AppColors.destructive,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      } catch (_) {
        // Fallback for other unexpected platform exceptions
      }
    }

    _uploads.pickAndUpload(slotIndex, source);
  }

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
                stepNumber: 1,
                stepCount: 2,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header and Subheader with Question Mark (Image 2)
                    Text(
                      'Verify your account',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Upload your ID and ownership document to get verified as a property owner. A business permit is optional.',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: context.appColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showFaqDialog(context),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.help_outline_rounded,
                              size: 20,
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 1: Government-issued ID (Image 1)
                    _SectionHeader(
                      title: 'Government-issued ID',
                      isRequired: true,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: BlocBuilder<ImageUploadCubit, ImageUploadState>(
                            bloc: _uploads,
                            buildWhen: (p, c) => p.slots[0] != c.slots[0],
                            builder: (context, state) => _DocumentCard(
                              slot: state.slots[0],
                              title: 'Front side',
                              subtitle: 'Upload photo',
                              iconWidget: const _IdFrontIcon(),
                              onTap: () => _handlePick(
                                0,
                                PickSource.gallery,
                              ),
                              onCameraTap: () => _handlePick(
                                0,
                                PickSource.camera,
                              ),
                              onRemove: () => _uploads.remove(0),
                              onRetry: () => _uploads.retry(0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BlocBuilder<ImageUploadCubit, ImageUploadState>(
                            bloc: _uploads,
                            buildWhen: (p, c) => p.slots[1] != c.slots[1],
                            builder: (context, state) => _DocumentCard(
                              slot: state.slots[1],
                              title: 'Back side',
                              subtitle: 'Upload photo',
                              iconWidget: const _IdBackIcon(),
                              onTap: () => _handlePick(
                                1,
                                PickSource.gallery,
                              ),
                              onCameraTap: () => _handlePick(
                                1,
                                PickSource.camera,
                              ),
                              onRemove: () => _uploads.remove(1),
                              onRetry: () => _uploads.retry(1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Property ownership document (Image 1)
                    _SectionHeader(
                      title: 'Property ownership document',
                      isRequired: true,
                    ),
                    const SizedBox(height: 10),
                    BlocBuilder<ImageUploadCubit, ImageUploadState>(
                      bloc: _uploads,
                      buildWhen: (p, c) => p.slots[2] != c.slots[2],
                      builder: (context, state) => _DocumentCard(
                        slot: state.slots[2],
                        title: 'Upload document',
                        subtitle: 'e.g. Title, Tax Declaration, or Contract',
                        iconWidget: const _DocSheetIcon(),
                        onTap: () => _handlePick(
                          2,
                          PickSource.gallery,
                        ),
                        onCameraTap: () => _handlePick(
                          2,
                          PickSource.camera,
                        ),
                        onRemove: () => _uploads.remove(2),
                        onRetry: () => _uploads.retry(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Business permit (if applicable) (Image 1)
                    _SectionHeader(
                      title: 'Business permit (if applicable)',
                      isRequired: false,
                    ),
                    const SizedBox(height: 10),
                    BlocBuilder<ImageUploadCubit, ImageUploadState>(
                      bloc: _uploads,
                      buildWhen: (p, c) => p.slots[3] != c.slots[3],
                      builder: (context, state) => _DocumentCard(
                        slot: state.slots[3],
                        title: 'Upload document',
                        subtitle: 'e.g. Mayor\'s Permit, DTI, or SEC',
                        iconWidget: const _DocSheetIcon(),
                        onTap: () => _handlePick(
                          3,
                          PickSource.gallery,
                        ),
                        onCameraTap: () => _handlePick(
                          3,
                          PickSource.camera,
                        ),
                        onRemove: () => _uploads.remove(3),
                        onRetry: () => _uploads.retry(3),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    BlocBuilder<ImageUploadCubit, ImageUploadState>(
                      bloc: _uploads,
                      builder: (context, state) => AppPrimaryButton(
                        label: _submitting
                            ? 'Submitting...'
                            : 'Submit for verification',
                        onPressed: state.isReady && !_submitting
                            ? _submit
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Documents are reviewed within 1–2 business days.',
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

// ── Section Header Row ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isRequired});

  final String title;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: title,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
          color: context.appColors.textPrimary,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Document Upload Card Widget ───────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.slot,
    required this.title,
    required this.subtitle,
    required this.iconWidget,
    required this.onTap,
    required this.onCameraTap,
    required this.onRemove,
    required this.onRetry,
  });

  final UploadSlot slot;
  final String title;
  final String subtitle;
  final Widget iconWidget;
  final VoidCallback onTap;
  final VoidCallback onCameraTap;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final status = slot.status;
    final isDashed = status != SlotStatus.success;

    final borderColor = switch (status) {
      SlotStatus.success => AppColors.primary,
      SlotStatus.failure => AppColors.destructive,
      _ => context.appColors.fieldBorder,
    };

    Widget card = Container(
      height: 110,
      decoration: BoxDecoration(
        color: status == SlotStatus.success
            ? const Color(0xFFF8FAFC)
            : context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(14),
        border: !isDashed
            ? Border.all(
                color: borderColor,
                width: 1.5,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Main Body
          if (status == SlotStatus.success)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (!kIsWeb && slot.localPath != null)
                      Image.file(
                        File(slot.localPath!),
                        fit: BoxFit.cover,
                      )
                    else if (slot.image?.url != null)
                      Image.network(
                        slot.image!.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _uploadedPlaceholder(context),
                      )
                    else
                      _uploadedPlaceholder(context),
                    Container(
                      color: AppColors.ink.withValues(alpha: 0.15),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: AppColors.matchHigh,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (status == SlotStatus.uploading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Uploading...',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else if (status == SlotStatus.failure)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.destructive,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload failed',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.destructive,
                    ),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Retry', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            )
          else
            // Empty State
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      iconWidget,
                      const SizedBox(height: 6),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10.0,
                          fontWeight: FontWeight.w400,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top-Right Action / Camera Button (Image 1)
          Positioned(
            top: 8,
            right: 8,
            child: status == SlotStatus.success
                ? GestureDetector(
                    onTap: onRemove,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.onInk,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.scrim.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: AppColors.destructive,
                      ),
                    ),
                  )
                : (status == SlotStatus.empty
                    ? GestureDetector(
                        onTap: onCameraTap,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.onInk,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.appColors.fieldBorder,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.scrim.withValues(alpha: 0.04),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 13,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      )
                    : const SizedBox.shrink()),
          ),
        ],
      ),
    );

    if (isDashed) {
      card = CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          color: borderColor,
          strokeWidth: 1.3,
          radius: 14,
        ),
        child: card,
      );
    }

    return card;
  }

  Widget _uploadedPlaceholder(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: const Icon(
        Icons.description_outlined,
        color: AppColors.primary,
        size: 32,
      ),
    );
  }
}

// ── Broken Line (Dashed) Border Painter ───────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.3,
    this.radius = 14.0,
  });

  static const double dashWidth = 5.0;
  static const double dashSpace = 3.5;

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final halfStroke = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        halfStroke,
        halfStroke,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}

// ── Custom Vector Icon Badges (Matching Image 1) ──────────────────────────────

class _IdFrontIcon extends StatelessWidget {
  const _IdFrontIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3.5),
        border: Border.all(color: AppColors.primary, width: 1.3),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 8.5,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 2.5),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 1.5,
                  width: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdBackIcon extends StatelessWidget {
  const _IdBackIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3.5),
        border: Border.all(color: AppColors.primary, width: 1.3),
      ),
      child: Column(
        children: [
          const SizedBox(height: 2),
          Container(
            height: 3.5,
            width: double.infinity,
            color: AppColors.primary,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: 2.5, right: 2.5, bottom: 2),
            child: Container(
              height: 1.5,
              width: 9,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocSheetIcon extends StatelessWidget {
  const _DocSheetIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3.5),
        border: Border.all(color: AppColors.primary, width: 1.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1.5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Container(
            height: 1.5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Container(
            height: 1.5,
            width: 7,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── FAQ Floating Dialog (Responsive, Non-bottom sheet, Subtle lines) ──────────

class _VerificationFaqDialog extends StatefulWidget {
  const _VerificationFaqDialog();

  @override
  State<_VerificationFaqDialog> createState() => _VerificationFaqDialogState();
}

class _VerificationFaqDialogState extends State<_VerificationFaqDialog> {
  int? _expandedIndex;

  static const List<(String, String)> _faqs = [
    (
      'Why do we need your documents?',
      'We collect your documents to verify your identity and property ownership, helping prevent fake accounts and fraudulent listings.',
    ),
    (
      'How will your information be used?',
      'Your documents are intended solely for identity and property ownership verification. They are not displayed on your public profile or used for advertising.',
    ),
    (
      'Who can access your documents?',
      'Access is restricted to authorized RentEase administrators responsible for reviewing verification requests.',
    ),
    (
      'Will my information be sold or shared?',
      'Your documents will not be sold or shared for advertising. Any disclosure must have a lawful basis and comply with applicable data privacy regulations.',
    ),
    (
      'How long are my documents kept?',
      'Your documents will be retained only as long as necessary for verification or legal requirements, after which they will be securely deleted.',
    ),
    (
      'Is my information secure?',
      'RentEase implements appropriate security measures to help protect your documents against unauthorized access, disclosure, and misuse.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.82;

    return Dialog(
      backgroundColor: context.appColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floating Card Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About your documents',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.appColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Learn how we use and protect your personal information.',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: context.appColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: context.appColors.textSecondary,
                    ),
                    splashRadius: 18,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: context.appColors.fieldBorder.withValues(alpha: 0.5),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Accordion items with subtle line separation (No carding)
                    for (int i = 0; i < _faqs.length; i++) ...[
                      InkWell(
                        onTap: () {
                          setState(() {
                            // Auto-close previously expanded item
                            _expandedIndex = _expandedIndex == i ? null : i;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _faqs[i].$1,
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13.5,
                                    fontWeight: _expandedIndex == i
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: _expandedIndex == i
                                        ? AppColors.primary
                                        : context.appColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _expandedIndex == i
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: _expandedIndex == i
                                    ? AppColors.primary
                                    : context.appColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_expandedIndex == i)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 2, 4, 10),
                          child: Text(
                            _faqs[i].$2,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              color: context.appColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: context.appColors.fieldBorder
                            .withValues(alpha: 0.5),
                      ),
                    ],

                    // Expandable "Protected under Philippine Law" (No icon, masked redirect link)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expandedIndex = _expandedIndex == _faqs.length
                              ? null
                              : _faqs.length;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Protected under Philippine Law',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 13.5,
                                  fontWeight: _expandedIndex == _faqs.length
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: _expandedIndex == _faqs.length
                                      ? AppColors.primary
                                      : context.appColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _expandedIndex == _faqs.length
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: _expandedIndex == _faqs.length
                                  ? AppColors.primary
                                  : context.appColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_expandedIndex == _faqs.length)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 2, 4, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Republic Act No. 10173, or the Data Privacy Act of 2012, requires lawful processing and appropriate protection of personal information. RentEase processes and stores your verification documents strictly to confirm identity and ownership, with safeguards against unauthorized access, disclosure, or misuse.',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: context.appColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () async {
                                final uri = Uri.parse(
                                  'https://privacy.gov.ph/data-privacy-act/',
                                );
                                try {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (_) {}
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Learn more about the Data Privacy Act',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Divider(
                      height: 1,
                      thickness: 0.8,
                      color: context.appColors.fieldBorder
                          .withValues(alpha: 0.5),
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
