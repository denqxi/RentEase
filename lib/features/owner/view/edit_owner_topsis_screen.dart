import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class EditOwnerTopsisScreen extends StatefulWidget {
  const EditOwnerTopsisScreen({
    this.initialCredibility = 0.60,
    this.initialProfile = 0.40,
    super.key,
  });

  final double initialCredibility;
  final double initialProfile;

  @override
  State<EditOwnerTopsisScreen> createState() => _EditOwnerTopsisScreenState();
}

class _EditOwnerTopsisScreenState extends State<EditOwnerTopsisScreen> {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit tenant ranking',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
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
                'Drag a slider — the other adjusts to keep the total at '
                '100%.',
                style: AppTextStyles.body(context),
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
                            style: AppTextStyles.label(
                              context,
                            ).copyWith(color: context.appColors.textSecondary),
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
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.ink,
                    foregroundColor: AppColors.onInk,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.button),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onInk,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  'Saving will re-rank your tenant matches.',
                  style: AppTextStyles.caption(context),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
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
