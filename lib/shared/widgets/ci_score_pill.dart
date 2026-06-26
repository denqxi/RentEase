import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Displays "Ci X.XX" formatted to 2 decimal places.
///
/// Tenant blue fill, tenant deep text, 20 px border radius.
class CiScorePill extends StatelessWidget {
  const CiScorePill({required this.score, super.key});

  final double score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.tenantFillBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Ci ${score.toStringAsFixed(2)}',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.tenantTextDeep,
        ),
      ),
    );
  }
}
