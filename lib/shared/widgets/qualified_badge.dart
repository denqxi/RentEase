import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// "Qualified" state badge — owner fill.
class QualifiedBadge extends StatelessWidget {
  const QualifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.ownerFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Qualified',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.ownerText,
        ),
      ),
    );
  }
}
