import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Two-state verification badge: verified (teal) or pending (amber).
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({this.isVerified = true, this.isSmall = false, super.key});

  final bool isVerified;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final double iconSize = isSmall ? 10 : 12;
    final double fontSize = 10;
    final EdgeInsets padding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 3);

    if (isVerified) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.accent, size: iconSize),
            SizedBox(width: 3),
            Text(
              'Verified owner',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.matchMedium, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_rounded, color: AppColors.matchMedium, size: iconSize),
            SizedBox(width: 3),
            Text(
              'Pending',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.matchMedium,
              ),
            ),
          ],
        ),
      );
    }
  }
}
