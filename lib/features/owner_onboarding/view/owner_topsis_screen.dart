import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class OwnerTopsisScreen extends StatefulWidget {
  const OwnerTopsisScreen({super.key});

  @override
  State<OwnerTopsisScreen> createState() => _OwnerTopsisScreenState();
}

class _OwnerTopsisScreenState extends State<OwnerTopsisScreen> {
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
      ),
    );
  }
}

class _SliderSection extends StatelessWidget {
  const _SliderSection({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final Color activeColor;

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
        ),
      ],
    );
  }
}
