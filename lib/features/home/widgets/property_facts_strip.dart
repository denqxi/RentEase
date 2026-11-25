import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/payment_breakdown.dart';

/// The facts a tenant decides on, readable without opening anything: move-in
/// total, distance, curfew and gender policy. Two columns, dropping to one on
/// narrow screens or large text, so no value is ever cut off.
class PropertyFactsStrip extends StatelessWidget {
  const PropertyFactsStrip({
    required this.breakdown,
    required this.curfewHours,
    required this.allowedGender,
    this.distanceKm,
    super.key,
  });

  final PaymentBreakdown breakdown;
  final num? curfewHours;
  final String allowedGender;

  /// Cached distance from the tenant's pinned place. Null (guests, no pin)
  /// leaves the fact out.
  final num? distanceKm;

  /// Narrowest column, at normal text size, that still holds two side by side.
  static const double _minColumnWidth = 104;

  @override
  Widget build(BuildContext context) {
    final km = distanceKm;
    final gender = allowedGender.trim();
    final facts = <(String, String)>[
      (
        'Move-in total',
        breakdown.moveInTotal > 0
            ? CurrencyUtils.formatDollars(breakdown.moveInTotal)
            : 'None',
      ),
      if (km != null && km.isFinite)
        ('Distance', '${km.toStringAsFixed(1)} km'),
      ('Curfew', formatCurfew(curfewHours)),
      (
        'Gender policy',
        gender.isEmpty || gender.toLowerCase() == 'any' ? 'Any gender' : gender,
      ),
    ];
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.fieldFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 16.0;
          final half = (constraints.maxWidth - gap) / 2;
          final twoColumns =
              half >= MediaQuery.textScalerOf(context).scale(_minColumnWidth);
          return Wrap(
            spacing: gap,
            runSpacing: 14,
            children: [
              for (final (label, value) in facts)
                SizedBox(
                  width: twoColumns ? half : constraints.maxWidth,
                  child: MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            height: 1.25,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
