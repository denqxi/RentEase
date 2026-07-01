import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../features/registration/widgets/step_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../model/property_draft.dart';

class OwnerTopsisScreen extends StatefulWidget {
  const OwnerTopsisScreen({
    this.initialStay = 0.50,
    this.initialCredibility = 0.30,
    this.initialProfile = 0.20,
    this.stepNumber = 3,
    this.stepCount = 3,
    super.key,
  });

  final double initialStay;
  final double initialCredibility;
  final double initialProfile;
  final int stepNumber;
  final int stepCount;

  @override
  State<OwnerTopsisScreen> createState() => _OwnerTopsisScreenState();
}

class _OwnerTopsisScreenState extends State<OwnerTopsisScreen> {
  late double _stay;
  late double _credibility;
  late double _profile;

  @override
  void initState() {
    super.initState();
    _stay = widget.initialStay;
    _credibility = widget.initialCredibility;
    _profile = widget.initialProfile;
  }

  double get _total => _stay + _credibility + _profile;
  bool get _isExact => (_total - 1.0).abs() < 0.001;

  double _round(double v) => (v * 20).round() / 20;

  void _commitDraftProperty() {
    final id = 'bh${100 + MockData.properties.length}';
    MockData.properties.add(<String, dynamic>{
      'id': id,
      'name': NewPropertyDraft.name,
      'address': NewPropertyDraft.address,
      'rent': NewPropertyDraft.rent,
      'distance': 1.0,
      'amenities': NewPropertyDraft.amenities.length,
      'ciScore': 0.75,
      'rank': MockData.properties.length + 1,
      'isVerified': true,
      'verifiedSince': 'Just now',
      'allowedGender': NewPropertyDraft.genderPolicy,
      'smokingAllowed': NewPropertyDraft.smokingAllowed,
      'petsAllowed': NewPropertyDraft.petsAllowed,
      'curfew': NewPropertyDraft.curfew,
      'deposit': NewPropertyDraft.deposit,
      'advanceMonths': NewPropertyDraft.advanceMonths,
      'ownerName': MockData.ownerName,
      'ownerInitials': MockData.ownerInitials,
      'memberSince': 'Jan 2025',
      'propertyCount': MockData.properties.length + 1,
      'amenityList': NewPropertyDraft.amenities.toList(),
      'bScore': 1,
      'isOutsidePreference': false,
      'vacancyStatus': 'available',
    });
    NewPropertyDraft.reset();
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
                stepNumber: widget.stepNumber,
                stepCount: widget.stepCount,
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
                      title: 'What matters most\nin a tenant?',
                      subtitle: 'Adjust the weights below to add up to 100%.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _WeightSlider(
                              label: 'Stay duration',
                              value: _stay,
                              onChanged: (v) =>
                                  setState(() => _stay = _round(v)),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _WeightSlider(
                              label: 'Credibility score',
                              value: _credibility,
                              onChanged: (v) =>
                                  setState(() => _credibility = _round(v)),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _WeightSlider(
                              label: 'Profile completeness',
                              value: _profile,
                              onChanged: (v) =>
                                  setState(() => _profile = _round(v)),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Divider(color: context.appColors.fieldBorder),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Text(
                                  'Total:',
                                  style: AppTextStyles.label(context).copyWith(
                                      color: context.appColors.textSecondary),
                                ),
                                const Spacer(),
                                if (_isExact) ...[
                                  Icon(Icons.check_circle_rounded,
                                      color: AppColors.accent, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '100%',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ] else ...[
                                  Icon(Icons.warning_amber_rounded,
                                      color: AppColors.destructive, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(_total * 100).round()}%',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.destructive,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppPrimaryButton(
                      label: 'Find Tenants',
                      onPressed: _isExact
                          ? () {
                              _commitDraftProperty();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRouter.landlordHome, (_) => false);
                            }
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Text(
                        'You can always adjust these weights later.',
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

class _WeightSlider extends StatelessWidget {
  const _WeightSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.label(context)
                    .copyWith(color: context.appColors.textPrimary),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: context.appColors.indicatorInactive,
            thumbColor: AppColors.accent,
            overlayColor: const Color(0x201F7D8C),
          ),
          child: Slider(
            value: value,
            min: 0.05,
            max: 0.90,
            divisions: 17,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
