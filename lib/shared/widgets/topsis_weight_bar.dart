import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Read-only weight display row for TOPSIS criteria.
///
/// Shows label on left, filled bar proportional to [weight], percentage on right.
class TopsisWeightBar extends StatelessWidget {
  const TopsisWeightBar({
    required this.label,
    required this.weight,
    required this.color,
    super.key,
  });

  final String label;

  /// Value between 0.0 and 1.0.
  final double weight;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(weight * 100).round()}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(
                        width: constraints.maxWidth,
                        color: AppColors.border,
                      ),
                      Container(
                        width: constraints.maxWidth * weight.clamp(0.0, 1.0),
                        color: color,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
