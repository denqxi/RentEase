import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

<<<<<<< Updated upstream
enum VerifiedState { verified, pending }

/// Badge showing owner verification status.
///
/// Set [isSmall] to reduce font size and padding for card use.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({
    required this.state,
    this.isSmall = false,
    super.key,
  });

  final VerifiedState state;

  /// Reduces font to 9 px and tightens padding for card use.
=======
/// Two-state verification badge: verified (teal) or pending (amber).
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({this.isVerified = true, this.isSmall = false, super.key});

  final bool isVerified;
>>>>>>> Stashed changes
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    final bool isVerified = state == VerifiedState.verified;

    final Color bg = isVerified ? AppColors.tenantFillTeal : AppColors.amberFill;
    final Color fg = isVerified ? AppColors.tenantTextTeal : AppColors.amberText;
    final IconData icon =
        isVerified ? Icons.check_circle_outline : Icons.access_time_outlined;
    final String label = isVerified ? 'Verified owner' : 'Pending verification';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 10,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 9 : 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isSmall ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
=======
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
>>>>>>> Stashed changes
  }
}
