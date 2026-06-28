import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Inquiry phase badge â€” Phase 1 (amber) or Phase 2 (teal).
class PhaseBadge extends StatelessWidget {
  const PhaseBadge({required this.phase, super.key});

  final int phase;

  @override
  Widget build(BuildContext context) {
    final isPhase2 = phase == 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPhase2 ? AppColors.accentSoft : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Phase $phase',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isPhase2 ? AppColors.accent : AppColors.matchMedium,
        ),
      ),
    );
  }
}
