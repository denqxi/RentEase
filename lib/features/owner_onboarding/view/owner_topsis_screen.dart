import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class OwnerTopsisScreen extends StatefulWidget {
  const OwnerTopsisScreen({super.key});
=======

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
>>>>>>> Stashed changes

  @override
  State<OwnerTopsisScreen> createState() => _OwnerTopsisScreenState();
}

class _OwnerTopsisScreenState extends State<OwnerTopsisScreen> {
<<<<<<< Updated upstream
  double budgetWeight = 0.50;
  double stayWeight = 0.30;
  double ratingWeight = 0.20;

  double get _total => budgetWeight + stayWeight + ratingWeight;

  bool get _isValid => (_total - 1.0).abs() < 0.01;

  @override
  Widget build(BuildContext context) {
    final totalPct = (_total * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rank your priorities.'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What matters most to you in a tenant?', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              'Adjust the sliders. Total must equal 100%.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),

            // Budget fit
            _SliderSection(
              label: 'Budget fit',
              value: budgetWeight,
              onChanged: (v) => setState(() => budgetWeight = v),
              activeColor: AppColors.ownerPrimary,
            ),
            const SizedBox(height: 16),

            // Stay duration
            _SliderSection(
              label: 'Stay duration',
              value: stayWeight,
              onChanged: (v) => setState(() => stayWeight = v),
              activeColor: AppColors.ownerPrimary,
            ),
            const SizedBox(height: 16),

            // Tenant rating
            _SliderSection(
              label: 'Tenant rating',
              value: ratingWeight,
              onChanged: (v) => setState(() => ratingWeight = v),
              activeColor: AppColors.ownerPrimary,
            ),
            const SizedBox(height: 16),

            // Total row
            Row(
              children: [
                Text(
                  'Total: $totalPct%',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isValid ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: _isValid ? AppColors.greenPrimary : AppColors.redPrimary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Find tenants',
              color: AppColors.ownerPrimary,
              onPressed: _isValid
                  ? () => Navigator.of(context).popUntil((r) => r.isFirst)
                  : null,
            ),
          ],
        ),
=======
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
>>>>>>> Stashed changes
      ),
    );
  }
}

<<<<<<< Updated upstream
class _SliderSection extends StatelessWidget {
  const _SliderSection({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });
=======
class _WeightSlider extends StatelessWidget {
  const _WeightSlider({required this.label, required this.value, required this.onChanged});
>>>>>>> Stashed changes

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
<<<<<<< Updated upstream
  final Color activeColor;
=======
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
<<<<<<< Updated upstream
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color: activeColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 1,
          divisions: 20,
          activeColor: activeColor,
          onChanged: onChanged,
=======
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
>>>>>>> Stashed changes
        ),
      ],
    );
  }
}
