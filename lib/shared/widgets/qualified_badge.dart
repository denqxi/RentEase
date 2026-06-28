import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

<<<<<<< Updated upstream
/// "Qualified" state badge — owner fill.
=======
/// Teal "Qualified" badge shown on matched tenants.
>>>>>>> Stashed changes
class QualifiedBadge extends StatelessWidget {
  const QualifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
<<<<<<< Updated upstream
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
=======
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Qualified',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
>>>>>>> Stashed changes
        ),
      ),
    );
  }
}
