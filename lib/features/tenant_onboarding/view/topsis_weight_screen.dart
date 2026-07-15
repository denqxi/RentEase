import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../features/registration/widgets/form_step_layout.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';

class TopsisWeightScreen extends StatefulWidget {
  const TopsisWeightScreen({
    this.initialRent = 0.40,
    this.initialDistance = 0.35,
    this.initialAmenities = 0.25,
    this.onSave,
    super.key,
  });

  final double initialRent;
  final double initialDistance;
  final double initialAmenities;
  final VoidCallback? onSave;

  @override
  State<TopsisWeightScreen> createState() => _TopsisWeightScreenState();
}

class _TopsisWeightScreenState extends State<TopsisWeightScreen> {
  late double _rent;
  late double _distance;
  late double _amenities;

  @override
  void initState() {
    super.initState();
    _rent = widget.initialRent;
    _distance = widget.initialDistance;
    _amenities = widget.initialAmenities;
  }

  double _round(double v) => (v * 20).round() / 20;

  /// Sets [changed] to [newValue] and redistributes the remainder across
  /// the other two weights proportionally to their current share, so the
  /// three always sum to exactly 1.0 (100%).
  void _setWeight({
    required double newValue,
    required double otherA,
    required double otherB,
    required ValueChanged<double> setChanged,
    required ValueChanged<double> setOtherA,
    required ValueChanged<double> setOtherB,
  }) {
    const double minWeight = 0.05;
    final double clamped = newValue.clamp(minWeight, 1 - 2 * minWeight);
    final double remainder = 1 - clamped;
    final double othersSum = otherA + otherB;

    double newA, newB;
    if (othersSum <= 0) {
      newA = remainder / 2;
      newB = remainder / 2;
    } else {
      newA = remainder * (otherA / othersSum);
      newB = remainder * (otherB / othersSum);
    }
    // Enforce the floor on both, then push any resulting slack back onto
    // whichever of the two has room, keeping the total exact.
    if (newA < minWeight) {
      newB -= (minWeight - newA);
      newA = minWeight;
    }
    if (newB < minWeight) {
      newA -= (minWeight - newB);
      newB = minWeight;
    }

    setState(() {
      setChanged(_round(clamped));
      setOtherA(_round(newA));
      setOtherB(_round(newB));
    });
  }

  void _continue() {
    if (widget.onSave != null) {
      widget.onSave!();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.matchingTransition,
        (_) => false,
        arguments: false, // tenant
      );
    }
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
                onBack: widget.onSave != null
                    ? () => Navigator.of(context).pop()
                    : () => Navigator.of(context).pop(),
                stepNumber: widget.onSave == null ? 5 : null,
                stepCount: widget.onSave == null ? 5 : null,
              ),
            ),
            Expanded(
              child: FormStepLayout(
                title: 'What matters most\nto you?',
                subtitle: 'Drag a slider — the others adjust to keep the '
                    'total at 100%.',
                buttonLabel: widget.onSave != null
                    ? 'Save Changes'
                    : 'Find My Matches',
                onContinue: _continue,
                fields: [
                  _WeightSlider(
                    label: 'Monthly rent',
                    value: _rent,
                    onChanged: (v) => _setWeight(
                      newValue: v,
                      otherA: _distance,
                      otherB: _amenities,
                      setChanged: (nv) => _rent = nv,
                      setOtherA: (nv) => _distance = nv,
                      setOtherB: (nv) => _amenities = nv,
                    ),
                  ),
                  _WeightSlider(
                    label: 'Distance from POI',
                    value: _distance,
                    onChanged: (v) => _setWeight(
                      newValue: v,
                      otherA: _rent,
                      otherB: _amenities,
                      setChanged: (nv) => _distance = nv,
                      setOtherA: (nv) => _rent = nv,
                      setOtherB: (nv) => _amenities = nv,
                    ),
                  ),
                  _WeightSlider(
                    label: 'Number of amenities',
                    value: _amenities,
                    onChanged: (v) => _setWeight(
                      newValue: v,
                      otherA: _rent,
                      otherB: _distance,
                      setChanged: (nv) => _amenities = nv,
                      setOtherA: (nv) => _rent = nv,
                      setOtherB: (nv) => _distance = nv,
                    ),
                  ),
                  Divider(color: context.appColors.fieldBorder),
                  Row(
                    children: [
                      Text('Total:',
                          style: AppTextStyles.label(context)
                              .copyWith(color: context.appColors.textSecondary)),
                      const Spacer(),
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.accent, size: 16),
                      SizedBox(width: 4),
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
                  if (widget.onSave != null)
                    Center(
                      child: Text(
                        'Saving will update your property ranking.',
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
                child: Text(label,
                    style: AppTextStyles.label(context)
                        .copyWith(color: context.appColors.textPrimary))),
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
