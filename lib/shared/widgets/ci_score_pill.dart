import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Compatibility Index score pill.
///
/// Tenant view: accentSoft background, accent text.
/// Owner view: fieldFill background, textSecondary text.
class CiScorePill extends StatelessWidget {
  const CiScorePill({required this.score, this.isOwner = false, super.key});

  final double score;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOwner ? context.appColors.fieldFill : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Ci ${score.toStringAsFixed(2)}',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isOwner ? context.appColors.textSecondary : AppColors.accent,
        ),
      ),
    );
  }
}
