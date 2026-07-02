import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/form_step_layout.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import 'topsis_weight_screen.dart';

class DistancePreferenceScreen extends StatefulWidget {
  const DistancePreferenceScreen({required this.poiName, super.key});

  final String poiName;

  @override
  State<DistancePreferenceScreen> createState() =>
      _DistancePreferenceScreenState();
}

class _DistancePreferenceScreenState
    extends State<DistancePreferenceScreen> {
  double _maxKm = 3.0;

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TopsisWeightScreen()),
    );
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
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
              ),
              child: RegistrationAppBar(
                onBack: () => Navigator.of(context).pop(),
                stepNumber: 4,
                stepCount: 5,
              ),
            ),
            Expanded(
              child: FormStepLayout(
                title: 'How far are you willing\nto travel?',
                subtitle:
                    "Set the maximum distance you're comfortable with.",
                buttonLabel: 'Save and Continue',
                onContinue: _continue,
                fields: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadii.field),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: AppColors.accent, size: 16),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            widget.poiName,
                            style: AppTextStyles.caption(context)
                                .copyWith(color: context.appColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Maximum distance',
                              style: AppTextStyles.label(context)),
                          Text(
                            '${_maxKm.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
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
                        ),
                        child: Slider(
                          value: _maxKm,
                          min: 0.5,
                          max: 10,
                          divisions: 19,
                          onChanged: (v) => setState(() => _maxKm = v),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: context.appColors.fieldFill,
                      borderRadius: BorderRadius.circular(AppRadii.field),
                      border: Border.all(color: context.appColors.fieldBorder),
                    ),
                    child: Text(
                      'Properties within ${_maxKm.toStringAsFixed(1)} km of ${widget.poiName} will appear in your results.',
                      style: AppTextStyles.caption(context)
                          .copyWith(color: context.appColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
