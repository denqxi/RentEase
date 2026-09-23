import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../shared/widgets/app_button.dart';

class EditTopsisScreen extends StatefulWidget {
  const EditTopsisScreen({super.key});

  @override
  State<EditTopsisScreen> createState() => _EditTopsisScreenState();
}

class _EditTopsisScreenState extends State<EditTopsisScreen> {
  double rentWeight = 0.35;
  double distanceWeight = 0.35;
  double amenitiesWeight = 0.30;

  double _round(double v) => (v * 20).round() / 20;

  void _setWeight({
    required double newValue,
    required double otherA,
    required double otherB,
    required ValueChanged<double> setChanged,
    required ValueChanged<double> setOtherA,
    required ValueChanged<double> setOtherB,
  }) {
    final result = normalizeWeights(
      newValue: newValue,
      otherA: otherA,
      otherB: otherB,
      round: _round,
    );
    setState(() {
      setChanged(result.changed);
      setOtherA(result.otherA);
      setOtherB(result.otherB);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    onChanged: (v) => _setWeight(
                      newValue: v,
                      otherA: distanceWeight,
                      otherB: amenitiesWeight,
                      setChanged: (nv) => rentWeight = nv,
                      setOtherA: (nv) => distanceWeight = nv,
                      setOtherB: (nv) => amenitiesWeight = nv,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Distance weight
                  _SliderSection(
                    label: 'Distance',
                    value: distanceWeight,
                    onChanged: (v) => _setWeight(
                      newValue: v,
                      otherA: rentWeight,
                      otherB: amenitiesWeight,
                      setChanged: (nv) => distanceWeight = nv,
                      setOtherA: (nv) => rentWeight = nv,
                      setOtherB: (nv) => amenitiesWeight = nv,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Amenities weight
                  _SliderSection(
                    label: 'Amenities',
                    value: amenitiesWeight,
                    onChanged: (v) => _setWeight(
                      newValue: v,
                      otherA: rentWeight,
                      otherB: distanceWeight,
                      setChanged: (nv) => amenitiesWeight = nv,
                      setOtherA: (nv) => rentWeight = nv,
                      setOtherB: (nv) => distanceWeight = nv,
                    ),
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
                      const Text(
                        '100%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.greenPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.check_circle_outline,
                          size: 16, color: AppColors.greenPrimary),
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
                  onPressed: () => Navigator.of(context).pop(),
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
