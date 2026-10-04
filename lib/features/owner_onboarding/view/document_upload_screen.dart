import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../features/registration/widgets/step_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/presentation/current_uid.dart';
import '../../../core/constants/cloudinary_config.dart';
import '../../uploads/data/repositories/cloudinary_image_upload_repository.dart';
import '../../uploads/domain/entities/uploaded_image.dart';
import '../../uploads/domain/repositories/image_upload_repository.dart';
import '../../uploads/presentation/cubit/image_upload_cubit.dart';
import '../../uploads/presentation/widgets/image_upload_slot.dart';
import '../cubit/owner_onboarding_cubit.dart';

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
    slotCount: CloudinaryConfig.documentCount,
    minRequired: CloudinaryConfig.requiredDocumentCount,
    // Slots 0 and 1 are required; slot 2 (business permit) is optional.
    requiredSlots: {0, 1},
  );

  @override
  void dispose() {
    _uploads.close();
    super.dispose();
  }

  bool _submitting = false;

  // Documents are uploaded to Cloudinary as they are picked; submitting stores
  // their URLs and records the verification request for admin review.
  Future<void> _submit() async {
    final uid = currentUidOrNull(context);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Your session has expired. Please sign in again.',
          ),
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
    // The pending screen follows the live status and offers "Continue to
    // Dashboard"; listings, Find Tenants and inquiries all work meanwhile
    // (verification only adds the Verified badge).
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.verificationPending, (_) => false);
  }

  static const List<String> _docLabels = [
    'Valid government ID',
    'Property ownership document',
    'Business permit (if applicable)',
  ];

  static bool _isOptional(int i) => i >= CloudinaryConfig.requiredDocumentCount;

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
                    const StepHeader(
                      title: 'Verify your account',
                      subtitle:
                          'Upload your ID and ownership document to get verified as a property owner. A business permit is optional.',
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            CloudinaryConfig.documentCount,
                            (i) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _docLabels[i],
                                          style: AppTextStyles.label(context),
                                        ),
                                      ),
                                      if (_isOptional(i)) ...[
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          'Optional',
                                          style: AppTextStyles.caption(context),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  BlocBuilder<
                                    ImageUploadCubit,
                                    ImageUploadState
                                  >(
                                    bloc: _uploads,
                                    buildWhen: (p, c) =>
                                        p.slots[i] != c.slots[i],
                                    builder: (context, state) =>
                                        ImageUploadSlot(
                                          slot: state.slots[i],
                                          height: 110,
                                          showPreview: false,
                                          emptyIcon: Icons.upload_rounded,
                                          emptyLabel: 'Tap to upload',
                                          onPick: (src) =>
                                              _uploads.pickAndUpload(i, src),
                                          onRetry: () => _uploads.retry(i),
                                          onRemove: () => _uploads.remove(i),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
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
                    SizedBox(height: AppSpacing.sm),
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
