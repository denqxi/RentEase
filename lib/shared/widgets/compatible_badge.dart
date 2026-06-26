import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// "Compatible" state badge — green fill.
class CompatibleBadge extends StatelessWidget {
  const CompatibleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.greenFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Compatible',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.greenText,
        ),
      ),
    );
  }
}
