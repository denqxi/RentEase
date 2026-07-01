import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';

class EditTopsisScreen extends StatefulWidget {
  const EditTopsisScreen({super.key});

  @override
  State<EditTopsisScreen> createState() => _EditTopsisScreenState();
}

class _EditTopsisScreenState extends State<EditTopsisScreen> {
  double rentWeight = 0.50;
  double distanceWeight = 0.30;
  double amenitiesWeight = 0.20;

  double get _total => rentWeight + distanceWeight + amenitiesWeight;
  bool get _isValid => (_total - 1.0).abs() < 0.001;

  @override
  Widget build(BuildContext context) {
    final totalPct = '${(_total * 100).round()}%';
    final totalColor = _isValid ? AppColors.greenPrimary : AppColors.redPrimary;
    final totalIcon = _isValid
        ? Icons.check_circle_outline
        : Icons.warning_amber_outlined;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit priorities',
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Rent weight
                  _SliderSection(
                    label: 'Monthly rent',
                    value: rentWeight,
                    onChanged: (v) => setState(() => rentWeight = v),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Distance weight
                  _SliderSection(
                    label: 'Distance',
                    value: distanceWeight,
                    onChanged: (v) => setState(() => distanceWeight = v),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Amenities weight
                  _SliderSection(
                    label: 'Amenities',
                    value: amenitiesWeight,
                    onChanged: (v) => setState(() => amenitiesWeight = v),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Total row
                  Row(
                    children: [
                      const Text(
                        'Total: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        totalPct,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: totalColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(totalIcon, size: 16, color: totalColor),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Column(
              children: [
                AppButton(
                  label: 'Save changes',
                  color: AppColors.ink,
                  onPressed:
                      _isValid ? () => Navigator.of(context).pop() : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Saving will update your property ranking.',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderSection extends StatelessWidget {
  const _SliderSection({
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
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 1,
          divisions: 20,
          activeColor: AppColors.ink,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
