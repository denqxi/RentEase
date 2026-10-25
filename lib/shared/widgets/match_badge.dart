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
    this.isLocked = false,
    this.ci,
    super.key,
  });

  final int percent;
  final bool showLabel;

  /// When true, renders a locked "Match Score" pill for guest users.
  final bool isLocked;
  final double? ci;

  /// Color psychology: green = strong match, amber = moderate, red = weak.
  static Color colorFor(int percent) => percent >= 80
      ? AppColors.matchHigh
      : percent >= 60
      ? AppColors.matchMedium
      : AppColors.destructive;

  Color get _dotColor => colorFor(percent);

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.scrim.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.lock_outline, color: AppColors.onInk, size: 11),
            const SizedBox(width: 4),
            Text(
              showLabel ? 'Match Score' : 'Score',
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

    final double ciVal = ci ?? (percent > 0 ? percent / 100.0 : 0.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.scrim.withValues(alpha: 0.60),
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
              const SizedBox(width: 4),
              Text(
                showLabel ? '$percent% match' : '$percent%',
                style: AppTextStyles.label(context).copyWith(
                  color: AppColors.onInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (percent > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppColors.ownerText.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.ownerPrimary.withValues(alpha: 0.6),
                width: 0.6,
              ),
            ),
            child: Text(
              'ci=${ciVal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                color: AppColors.indigo50,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
