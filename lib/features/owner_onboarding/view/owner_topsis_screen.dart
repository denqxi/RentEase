import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/card_over_hero_layout.dart';

class OwnerTopsisScreen extends StatefulWidget {
  const OwnerTopsisScreen({
    this.initialStay = 0.50,
    this.initialCredibility = 0.30,
    this.initialProfile = 0.20,
    this.onSave,
    super.key,
  });

  final double initialStay;
  final double initialCredibility;
  final double initialProfile;
  final VoidCallback? onSave;

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

  @override
  Widget build(BuildContext context) {
    return CardOverHeroLayout(
      hero: const HeroPlaceholder(),
      cardContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What matters most\nin a tenant?',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text('Adjust weights to add up to 100%.', style: AppTextStyles.body(context)),
          SizedBox(height: AppSpacing.lg),
          _WeightSlider(
            label: 'Stay duration',
            value: _stay,
            onChanged: (v) => setState(() => _stay = _round(v)),
          ),
          SizedBox(height: AppSpacing.md),
          _WeightSlider(
            label: 'Credibility score',
            value: _credibility,
            onChanged: (v) => setState(() => _credibility = _round(v)),
          ),
          SizedBox(height: AppSpacing.md),
          _WeightSlider(
            label: 'Profile completeness',
            value: _profile,
            onChanged: (v) => setState(() => _profile = _round(v)),
          ),
          SizedBox(height: AppSpacing.md),
          Divider(color: context.appColors.fieldBorder),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text('Total:', style: AppTextStyles.label(context).copyWith(color: context.appColors.textSecondary)),
              const Spacer(),
              if (_isExact) ...[
                Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 16),
                SizedBox(width: 4),
                Text('100%', style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
              ] else ...[
                Icon(Icons.warning_amber_rounded, color: AppColors.destructive, size: 16),
                SizedBox(width: 4),
                Text('${(_total * 100).round()}%', style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.destructive)),
              ],
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: ElevatedButton(
              onPressed: _isExact
                  ? () {
                      if (widget.onSave != null) {
                        widget.onSave!();
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushNamedAndRemoveUntil('/owner/properties', (_) => false);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isExact ? context.appColors.ink : context.appColors.indicatorInactive,
                foregroundColor: _isExact ? AppColors.onInk : context.appColors.textSecondary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
              ),
              child: Text(
                widget.onSave != null ? 'Save Changes' : 'Find Tenants',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _isExact ? AppColors.onInk : context.appColors.textSecondary,
                ),
              ),
            ),
          ),
          if (widget.onSave != null) ...[
            SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                'Saving will re-rank your tenant matches.',
                style: AppTextStyles.caption(context),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _WeightSlider extends StatelessWidget {
  const _WeightSlider({required this.label, required this.value, required this.onChanged});

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
            Expanded(child: Text(label, style: AppTextStyles.label(context).copyWith(color: context.appColors.textPrimary))),
            Text('${(value * 100).round()}%', style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: context.appColors.indicatorInactive,
            thumbColor: AppColors.accent,
            overlayColor: const Color(0x201F7D8C),
          ),
          child: Slider(value: value, min: 0.05, max: 0.90, divisions: 17, onChanged: onChanged),
        ),
      ],
    );
  }
}
