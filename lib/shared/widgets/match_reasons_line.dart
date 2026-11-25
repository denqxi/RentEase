import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../features/matching/domain/entities/match_reason.dart';

/// The card line that says why a listing suits the tenant. Wraps to a second
/// line on narrow screens or large text, and takes no space when empty.
class MatchReasonsLine extends StatelessWidget {
  const MatchReasonsLine({required this.reasons, this.maxLines = 2, super.key});

  final List<MatchReason> reasons;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (reasons.isEmpty) return const SizedBox.shrink();
    return Text(
      reasons.map((r) => r.shortLabel).join(' · '),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: context.appColors.textPrimary,
        height: 1.25,
      ),
    );
  }
}
