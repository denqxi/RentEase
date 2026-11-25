import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// The owner's listing counts on one compact row. Wraps at large text, so no
/// label is ever cut off.
class PortfolioStatsRow extends StatelessWidget {
  const PortfolioStatsRow({
    required this.total,
    required this.available,
    super.key,
  });

  final int total;
  final int available;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // One row at ordinary text sizes: three equal columns, label under value.
    final oneRow = MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    Widget stat(int value, String label, [Color? dot]) => MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  height: 1.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (dot != null) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
    final stats = [
      stat(total, total == 1 ? 'Listing' : 'Listings'),
      stat(available, 'Available', AppColors.matchHigh),
      stat(total - available, 'Occupied', AppColors.matchMedium),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.fieldFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: oneRow
            ? Row(children: [for (final s in stats) Expanded(child: s)])
            : Wrap(spacing: 24, runSpacing: 10, children: stats),
      ),
    );
  }
}
