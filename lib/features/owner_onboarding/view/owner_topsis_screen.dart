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
    this.initialCredibility = 0.60,
    this.initialProfile = 0.40,
    this.stepNumber = 3,
    this.stepCount = 3,
    super.key,
  });

  final double initialCredibility;
  final double initialProfile;
  final int stepNumber;
  final int stepCount;

  @override
  State<OwnerTopsisScreen> createState() => _OwnerTopsisScreenState();
}

class _OwnerTopsisScreenState extends State<OwnerTopsisScreen> {
  late double _credibility;
  late double _profile;

  @override
  void initState() {
    super.initState();
    _credibility = widget.initialCredibility;
    _profile = widget.initialProfile;
  }

  double _round(double v) => (v * 20).round() / 20;

  /// Two criteria: moving one slider sets the other to the remainder so the
  /// pair always sums to exactly 1.0.
  void _setCredibility(double v) {
    final c = _round(v.clamp(0.05, 0.95));
    setState(() {
      _credibility = c;
      _profile = _round(1 - c);
    });
  }

  void _setProfile(double v) {
    final p = _round(v.clamp(0.05, 0.95));
    setState(() {
      _profile = p;
      _credibility = _round(1 - p);
    });
  }

  void _commitDraftProperty() {
    final id = 'bh${100 + MockData.properties.length}';
    MockData.properties.add(<String, dynamic>{
      'propertyId': id,
      'title': NewPropertyDraft.name,
      'address': NewPropertyDraft.address,
      'monthlyRent': NewPropertyDraft.rent,
      'distance': 1.0,
      'amenityScore': NewPropertyDraft.amenities.length,
      'tenantCi': 0.75,
      'tenantRank': MockData.properties.length + 1,
      'isVerified': true,
      'verifiedSince': 'Just now',
      'allowedGender': NewPropertyDraft.genderPolicy,
      'smokingAllowed': NewPropertyDraft.smokingAllowed,
      'petsAllowed': NewPropertyDraft.petsAllowed,
      'curfewHours': NewPropertyDraft.curfewHours,
      'depositAmount': NewPropertyDraft.deposit,
      'advanceMonths': NewPropertyDraft.advanceMonths,
      'ownerName': MockData.ownerName,
      'ownerInitials': MockData.ownerInitials,
      'memberSince': 'Jan 2025',
      'propertyCount': MockData.properties.length + 1,
      'amenityList': NewPropertyDraft.amenities.toList(),
      'bScore': 1,
      'isOutsidePreference': false,
      'vacancyStatus': 'available',
      'isAvailable': true,
      // Fall back to the Matina area when the owner skipped map pinning,
      // so the property always renders on the tenant map view.
      'latitude': NewPropertyDraft.latitude ?? 7.0660,
      'longitude': NewPropertyDraft.longitude ?? 125.6030,
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
                      subtitle:
                          'Drag a slider — the other adjusts to keep '
                          'the total at 100%.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _WeightSlider(
                              label: 'Credibility score',
                              value: _credibility,
                              onChanged: _setCredibility,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _WeightSlider(
                              label: 'Profile completeness',
                              value: _profile,
                              onChanged: _setProfile,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Divider(color: context.appColors.fieldBorder),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Text(
                                  'Total:',
                                  style: AppTextStyles.label(context).copyWith(
                                    color: context.appColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.accent,
                                  size: 16,
                                ),
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
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppPrimaryButton(
                      label: 'Find Tenants',
                      onPressed: () {
                        _commitDraftProperty();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRouter.matchingTransition,
                          (_) => false,
                          arguments: true, // owner
                        );
                      },
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
                style: AppTextStyles.label(
                  context,
                ).copyWith(color: context.appColors.textPrimary),
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
