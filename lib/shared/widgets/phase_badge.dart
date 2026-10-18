import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Inquiry phase badge — Phase 1 or Phase 2 styled with soft theme blue.
class PhaseBadge extends StatelessWidget {
  const PhaseBadge({required this.phase, super.key});

  final int phase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Phase $phase',
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          height: 1.15,
        ),
      ),
    );
  }
}
