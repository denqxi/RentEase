import 'package:flutter/material.dart';
<<<<<<< Updated upstream
=======

>>>>>>> Stashed changes
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
<<<<<<< Updated upstream
=======
import '../../../shared/widgets/card_over_hero_layout.dart';
import 'verification_pending_screen.dart';
>>>>>>> Stashed changes

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
<<<<<<< Updated upstream
  List<bool> uploaded = [false, false, false];

  final List<String> _labels = [
    'Valid government ID',
    'Proof of ownership or barangay certificate',
    'Property photos (minimum 3)',
=======
  final List<bool> _uploaded = [false, false, false];

  bool get _allUploaded => _uploaded.every((v) => v);

  static const List<String> _docLabels = [
    'Valid government ID',
    'Property ownership document',
    'Business permit (if applicable)',
>>>>>>> Stashed changes
  ];

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload the required documents to start listing properties.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),
            ...List.generate(3, (i) {
              final isUploaded = uploaded[i];
              return GestureDetector(
                onTap: () => setState(() => uploaded[i] = true),
                child: Container(
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isUploaded ? AppColors.tenantFillBlue : AppColors.fieldBg,
                    border: Border.all(
                      color: isUploaded ? AppColors.primaryMid : AppColors.border,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.field),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isUploaded ? Icons.check_circle : Icons.upload_outlined,
                        color: isUploaded ? AppColors.primaryMid : AppColors.textHint,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _labels[i],
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
=======
    return CardOverHeroLayout(
      hero: const HeroPlaceholder(),
      cardContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(currentStep: 0, totalSteps: 3, label: 'Step 1 of 3'),
          SizedBox(height: AppSpacing.md),
          Text(
            'Verify your account.',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Upload the required documents to get verified as a property owner.',
            style: AppTextStyles.body(context),
          ),
          SizedBox(height: AppSpacing.lg),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GestureDetector(
              onTap: () => setState(() => _uploaded[i] = !_uploaded[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 80,
                decoration: BoxDecoration(
                  color: _uploaded[i] ? AppColors.accentSoft : context.appColors.fieldFill,
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  border: Border.all(
                    color: _uploaded[i] ? AppColors.accent : context.appColors.fieldBorder,
                    width: _uploaded[i] ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _uploaded[i] ? Icons.check_circle_rounded : Icons.upload_rounded,
                        color: _uploaded[i] ? AppColors.accent : context.appColors.hint,
                        size: 24,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        _docLabels[i],
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: _uploaded[i] ? AppColors.accent : context.appColors.textSecondary,
                          fontWeight: _uploaded[i] ? FontWeight.w600 : FontWeight.w400,
>>>>>>> Stashed changes
                        ),
                      ),
                    ],
                  ),
                ),
<<<<<<< Updated upstream
              );
            }),
            const SizedBox(height: 32),
            AppButton(
              label: 'Submit for verification',
              color: AppColors.ownerPrimary,
              onPressed: uploaded.every((u) => u) ? () {} : null,
            ),
            const SizedBox(height: 12),
            Text(
              'Admin will review your documents within 24–48 hours.',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
=======
              ),
            ),
          )),
          AppButton(
            label: 'Submit for verification',
            onPressed: _allUploaded
                ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const VerificationPendingScreen(),
                      ),
                    )
                : null,
          ),
          SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              'Documents are reviewed within 1â€“2 business days.',
              style: AppTextStyles.caption(context),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
        ],
>>>>>>> Stashed changes
      ),
    );
  }
}
