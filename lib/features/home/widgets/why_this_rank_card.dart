import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/firestore/models/models.dart';
import '../../matching/domain/entities/match_reason.dart';

/// Explains a match's position: the plain reasons first, then the TOPSIS
/// closeness score and the tenant's weights. The only place the score shows.
class WhyThisRankCard extends StatelessWidget {
  const WhyThisRankCard({
    required this.ci,
    required this.reasons,
    this.rank,
    this.profile,
    super.key,
  });

  /// Cached TOPSIS closeness coefficient, 0–1. Never computed here.
  final double ci;
  final List<MatchReason> reasons;

  /// 1-based rank; null or 0 when unknown.
  final int? rank;
  final TenantProfileDoc? profile;

  static IconData _icon(MatchReasonKind kind) => switch (kind) {
    MatchReasonKind.distance => Icons.near_me_outlined,
    MatchReasonKind.budget => Icons.payments_outlined,
    MatchReasonKind.amenities => Icons.checklist_rounded,
  };

  static String _percent(num weight) => '${(weight * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    TextStyle text(double size, FontWeight weight, Color color) => TextStyle(
      fontFamily: 'DM Sans',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.35,
    );
    final body = text(13, FontWeight.w500, colors.textPrimary);
    final muted = text(12, FontWeight.w400, colors.textSecondary);
    final position = rank;
    final weights = profile;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.fieldBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why this rank?',
            style: text(15, FontWeight.w800, colors.textPrimary),
          ),
          if (position != null && position > 0) ...[
            const SizedBox(height: 2),
            Text('Number $position among your matches', style: muted),
          ],
          const SizedBox(height: 8),
          for (final r in reasons)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_icon(r.kind), size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.detailLabel, style: body)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colors.fieldBorder),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('Ranking score (Ci)', style: body)),
              Text(
                ci.toStringAsFixed(4),
                style: text(15, FontWeight.w800, colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'From 0 to 1. Higher means closer to the best mix of rent, '
            'distance and amenities among your matches.',
            style: muted,
          ),
          if (weights != null) ...[
            const SizedBox(height: 4),
            Text(
              'Your priorities: rent ${_percent(weights.wRent)}, '
              'distance ${_percent(weights.wDistance)}, '
              'amenities ${_percent(weights.wAmenities)}.',
              style: muted,
            ),
          ],
        ],
      ),
    );
  }
}
