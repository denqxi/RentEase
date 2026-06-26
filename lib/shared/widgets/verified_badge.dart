import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

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
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
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
  }
}
