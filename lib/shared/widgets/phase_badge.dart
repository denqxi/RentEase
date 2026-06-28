import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

<<<<<<< Updated upstream
/// Shows "Phase 1" or "Phase 2" with appropriate color coding.
///
/// Phase 1: amber fill / text. Phase 2: tenant blue fill / text.
=======
/// Inquiry phase badge â€” Phase 1 (amber) or Phase 2 (teal).
>>>>>>> Stashed changes
class PhaseBadge extends StatelessWidget {
  const PhaseBadge({required this.phase, super.key});

  final int phase;

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    final bool isPhase1 = phase == 1;
    final Color bg = isPhase1 ? AppColors.amberFill : AppColors.tenantFillBlue;
    final Color fg = isPhase1 ? AppColors.amberText : AppColors.tenantTextDeep;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
=======
    final isPhase2 = phase == 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPhase2 ? AppColors.accentSoft : const Color(0xFFFEF3C7),
>>>>>>> Stashed changes
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Phase $phase',
        style: TextStyle(
<<<<<<< Updated upstream
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
=======
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isPhase2 ? AppColors.accent : AppColors.matchMedium,
>>>>>>> Stashed changes
        ),
      ),
    );
  }
}
