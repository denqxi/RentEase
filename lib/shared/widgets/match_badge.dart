import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Pill overlay marking a listing as a match; guests see it locked.
class MatchBadge extends StatelessWidget {
  const MatchBadge({this.isLocked = false, super.key});

  /// When true, renders a locked "Match" pill for guest users.
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.scrim.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isLocked ? Icons.lock_outline : Icons.check_circle_rounded,
            color: AppColors.onInk,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            isLocked ? 'Match' : 'Matches',
            style: AppTextStyles.label(context).copyWith(
              color: AppColors.onInk,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
