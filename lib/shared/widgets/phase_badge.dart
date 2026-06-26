import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Shows "Phase 1" or "Phase 2" with appropriate color coding.
///
/// Phase 1: amber fill / text. Phase 2: tenant blue fill / text.
class PhaseBadge extends StatelessWidget {
  const PhaseBadge({required this.phase, super.key});

  final int phase;

  @override
  Widget build(BuildContext context) {
    final bool isPhase1 = phase == 1;
    final Color bg = isPhase1 ? AppColors.amberFill : AppColors.tenantFillBlue;
    final Color fg = isPhase1 ? AppColors.amberText : AppColors.tenantTextDeep;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Phase $phase',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
