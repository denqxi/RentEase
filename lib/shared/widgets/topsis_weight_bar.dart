import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Read-only horizontal weight bar for TOPSIS criteria visualization.
class TopsisWeightBar extends StatelessWidget {
  const TopsisWeightBar({
    required this.label,
    required this.weight,
    this.color = AppColors.accent,
    super.key,
  });

  final String label;
  final double weight;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
