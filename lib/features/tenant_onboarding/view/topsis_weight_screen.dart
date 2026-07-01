import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../features/registration/widgets/form_step_layout.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';

class TopsisWeightScreen extends StatefulWidget {
  const TopsisWeightScreen({
    this.initialRent = 0.50,
    this.initialDistance = 0.30,
    this.initialAmenities = 0.20,
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

  double get _total => _rent + _distance + _amenities;
  bool get _isExact => (_total - 1.0).abs() < 0.001;

  double _round(double v) => (v * 20).round() / 20;

  void _continue() {
    if (widget.onSave != null) {
      widget.onSave!();
    } else {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRouter.tenantHome, (_) => false);
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
                stepNumber: widget.onSave == null ? 4 : null,
                stepCount: widget.onSave == null ? 4 : null,
              ),
            ),
            Expanded(
              child: FormStepLayout(
                title: 'What matters most\nto you?',
                subtitle: 'Adjust the sliders so they add up to 100%.',
                buttonLabel: widget.onSave != null
                    ? 'Save Changes'
                    : 'Find My Matches',
                onContinue: _isExact ? _continue : null,
                fields: [
                  _WeightSlider(
                    label: 'Monthly rent',
                    value: _rent,
                    onChanged: (v) => setState(() => _rent = _round(v)),
                  ),
                  _WeightSlider(
                    label: 'Distance from POI',
                    value: _distance,
                    onChanged: (v) => setState(() => _distance = _round(v)),
                  ),
                  _WeightSlider(
                    label: 'Number of amenities',
                    value: _amenities,
                    onChanged: (v) =>
                        setState(() => _amenities = _round(v)),
                  ),
                  Divider(color: context.appColors.fieldBorder),
                  Row(
                    children: [
                      Text('Total:',
                          style: AppTextStyles.label(context)
                              .copyWith(color: context.appColors.textSecondary)),
                      const Spacer(),
                      if (_isExact) ...[
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
                      ] else ...[
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.destructive, size: 16),
                        SizedBox(width: 4),
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
