import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

<<<<<<< Updated upstream
/// Read-only weight display row for TOPSIS criteria.
///
/// Shows label on left, filled bar proportional to [weight], percentage on right.
=======
/// Read-only horizontal weight bar for TOPSIS criteria visualization.
>>>>>>> Stashed changes
class TopsisWeightBar extends StatelessWidget {
  const TopsisWeightBar({
    required this.label,
    required this.weight,
<<<<<<< Updated upstream
    required this.color,
=======
    this.color = AppColors.accent,
>>>>>>> Stashed changes
    super.key,
  });

  final String label;
<<<<<<< Updated upstream

  /// Value between 0.0 and 1.0.
  final double weight;

=======
  final double weight;
>>>>>>> Stashed changes
  final Color color;

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
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
=======
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: weight.clamp(0.0, 1.0),
                backgroundColor: context.appColors.indicatorInactive,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${(weight * 100).round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
>>>>>>> Stashed changes
              ),
            ),
          ),
        ],
      ),
    );
  }
}
