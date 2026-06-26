import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

class TopsisWeightScreen extends StatefulWidget {
  const TopsisWeightScreen({this.onComplete, super.key});

  final VoidCallback? onComplete;

  @override
  State<TopsisWeightScreen> createState() => _TopsisWeightScreenState();
}

class _TopsisWeightScreenState extends State<TopsisWeightScreen> {
  double _rent = 0.50;
  double _distance = 0.30;
  double _amenities = 0.20;

  double get _total => _rent + _distance + _amenities;
  bool get _isValid => (_total - 1.0).abs() < 0.01;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left,
              color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Priorities',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Step progress bar — all 3 filled
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryMid,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryMid,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryMid,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Step 3 of 3',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'What matters most to you?',
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Adjust the sliders. Total must equal 100%.',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 24),
                  // Monthly Rent slider
                  _WeightSlider(
                    label: 'Monthly Rent',
                    value: _rent,
                    onChanged: (v) => setState(() => _rent = v),
                  ),
                  const SizedBox(height: 8),
                  // Distance slider
                  _WeightSlider(
                    label: 'Distance from POI',
                    value: _distance,
                    onChanged: (v) => setState(() => _distance = v),
                  ),
                  const SizedBox(height: 8),
                  // Amenities slider
                  _WeightSlider(
                    label: 'Amenities',
                    value: _amenities,
                    onChanged: (v) => setState(() => _amenities = v),
                  ),
                  const SizedBox(height: 16),
                  // Total indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isValid
                          ? AppColors.greenFill
                          : AppColors.amberFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isValid
                              ? Icons.check_circle
                              : Icons.warning_amber_rounded,
                          color: _isValid
                              ? AppColors.greenPrimary
                              : AppColors.amberPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total: ${(_total * 100).round()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isValid
                                ? AppColors.greenText
                                : AppColors.amberText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: AppPrimaryButton(
              label: 'Find My Matches',
              onPressed: _isValid
                  ? () {
                      if (widget.onComplete != null) {
                        widget.onComplete!();
                      } else {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    }
                  : null,
            ),
          ),
        ],
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryMid,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryMid,
            thumbColor: AppColors.primaryMid,
            inactiveTrackColor: AppColors.border,
            overlayColor: AppColors.primaryMid.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
