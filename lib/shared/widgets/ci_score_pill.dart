import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

<<<<<<< Updated upstream
/// Displays "Ci X.XX" formatted to 2 decimal places.
///
/// Tenant blue fill, tenant deep text, 20 px border radius.
class CiScorePill extends StatelessWidget {
  const CiScorePill({required this.score, super.key});

  final double score;
=======
/// Compatibility Index score pill.
///
/// Tenant view: accentSoft background, accent text.
/// Owner view: fieldFill background, textSecondary text.
class CiScorePill extends StatelessWidget {
  const CiScorePill({required this.score, this.isOwner = false, super.key});

  final double score;
  final bool isOwner;
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
<<<<<<< Updated upstream
        color: AppColors.tenantFillBlue,
=======
        color: isOwner ? context.appColors.fieldFill : AppColors.accentSoft,
>>>>>>> Stashed changes
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Ci ${score.toStringAsFixed(2)}',
<<<<<<< Updated upstream
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.tenantTextDeep,
=======
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isOwner ? context.appColors.textSecondary : AppColors.accent,
>>>>>>> Stashed changes
        ),
      ),
    );
  }
}
