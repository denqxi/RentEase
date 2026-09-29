import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../features/registration/widgets/step_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/presentation/current_uid.dart';
import '../cubit/owner_onboarding_cubit.dart';
import 'verification_pending_screen.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final List<bool> _uploaded = [false, false, false];

  bool get _allUploaded => _uploaded.every((v) => v);

  bool _submitting = false;

  // File upload needs Firebase Storage (Blaze plan) — not enabled on this
  // project yet. The toggles stand in for picking files; submitting records
  // the verification request itself so an admin can approve the owner.
  Future<void> _submit() async {
    final uid = currentUidOrNull(context);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Your session has expired. Please sign in again.'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }
    final cubit = context.read<OwnerOnboardingCubit>();
    setState(() => _submitting = true);
    await cubit.submitForVerification(uid);
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const VerificationPendingScreen()),
    );
  }

  static const List<String> _docLabels = [
    'Valid government ID',
    'Property ownership document',
    'Business permit (if applicable)',
  ];

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
                          'Upload the required documents to get verified as a property owner.',
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(3, (i) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: GestureDetector(
                              onTap: () => setState(() => _uploaded[i] = !_uploaded[i]),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _uploaded[i]
                                      ? AppColors.accentSoft
                                      : context.appColors.fieldFill,
                                  borderRadius: BorderRadius.circular(AppRadii.field),
                                  border: Border.all(
                                    color: _uploaded[i]
                                        ? AppColors.accent
                                        : context.appColors.fieldBorder,
                                    width: _uploaded[i] ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _uploaded[i]
                                            ? Icons.check_circle_rounded
                                            : Icons.upload_rounded,
                                        color: _uploaded[i]
                                            ? AppColors.accent
                                            : context.appColors.hint,
                                        size: 24,
                                      ),
                                      SizedBox(width: AppSpacing.sm),
                                      Text(
                                        _docLabels[i],
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 13,
                                          color: _uploaded[i]
                                              ? AppColors.accent
                                              : context.appColors.textSecondary,
                                          fontWeight: _uploaded[i]
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    AppPrimaryButton(
                      label: _submitting
                          ? 'Submitting...'
                          : 'Submit for verification',
                      onPressed: _allUploaded && !_submitting ? _submit : null,
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
