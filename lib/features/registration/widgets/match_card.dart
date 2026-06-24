import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/match_result.dart';

/// Compact card summarising a top listing match on the success screen.
class MatchCard extends StatelessWidget {
  const MatchCard({required this.match, super.key});

  final MatchResult match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadii.chip),
            ),
            child: Text(
              '${match.scorePercent}%',
              style: AppTextStyles.label.copyWith(
                color: AppColors.onInk,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(match.title, style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.xs),
                Text(match.location, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
