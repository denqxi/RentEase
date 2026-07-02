import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Pill overlay displaying a listing's match score.
///
/// Set [showLabel] to true for the "92% match" form (large cards); false
/// renders the compact "92%" form used in row thumbnails.
class MatchBadge extends StatelessWidget {
  const MatchBadge({
    required this.percent,
    this.showLabel = false,
    super.key,
  });

  final int percent;
  final bool showLabel;

  /// Color psychology: green = strong match, amber = moderate, red = weak.
  static Color colorFor(int percent) => percent >= 80
      ? AppColors.matchHigh
      : percent >= 60
          ? AppColors.matchMedium
          : AppColors.destructive;

  Color get _dotColor => colorFor(percent);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _dotColor,
            ),
          ),
          SizedBox(width: 4),
          Text(
            showLabel ? '$percent% match' : '$percent%',
            style: AppTextStyles.label(context).copyWith(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
