import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/payment_breakdown.dart';

/// Itemised move-in cost for a listing: monthly rent, advance rent, security
/// deposit, and the total due at move-in. The arithmetic lives in
/// [PaymentBreakdown]; this widget only formats it.
class PaymentBreakdownCard extends StatelessWidget {
  const PaymentBreakdownCard({
    required this.breakdown,
    this.title = 'Payment breakdown',
    this.monthlyRentLabel = 'Monthly rent',
    this.advanceLabel = 'Advance rent',
    this.depositLabel = 'Security deposit',
    this.totalLabel = 'Total due at move-in',
    this.noneLabel = 'None',
    this.monthsLabel,
    this.showMonthlyRent = true,
    super.key,
  });

  final PaymentBreakdown breakdown;

  /// Off where the screen already shows the rent.
  final bool showMonthlyRent;
  final String title;
  final String monthlyRentLabel;
  final String advanceLabel;
  final String depositLabel;
  final String totalLabel;
  final String noneLabel;

  /// Formats the advance month count, e.g. `2 months`. Defaults to English.
  final String Function(num months)? monthsLabel;

  static String _defaultMonths(num months) =>
      '${_trim(months)} ${months == 1 ? 'month' : 'months'}';

  static String _trim(num value) =>
      value == value.roundToDouble() ? value.round().toString() : '$value';

  @override
  Widget build(BuildContext context) {
    final b = breakdown;
    final months = (monthsLabel ?? _defaultMonths)(b.advanceMonths);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (showMonthlyRent)
            _line(
            context,
            monthlyRentLabel,
            CurrencyUtils.formatDollars(b.monthlyRent),
          ),
          _line(
            context,
            b.advanceMonths <= 0
                ? advanceLabel
                : showMonthlyRent
                ? '$advanceLabel ($months × '
                      '${CurrencyUtils.formatDollars(b.monthlyRent)})'
                : '$advanceLabel ($months)',
            b.advanceMonths > 0
                ? CurrencyUtils.formatDollars(b.advanceTotal)
                : noneLabel,
          ),
          _line(
            context,
            depositLabel,
            b.depositAmount > 0
                ? CurrencyUtils.formatDollars(b.depositAmount)
                : noneLabel,
          ),
          Divider(
            height: 16,
            thickness: 0.8,
            color: context.appColors.fieldBorder,
          ),
          _line(
            context,
            totalLabel,
            CurrencyUtils.formatDollars(b.moveInTotal),
            emphasised: true,
          ),
        ],
      ),
    );
  }

  Widget _line(
    BuildContext context,
    String label,
    String value, {
    bool emphasised = false,
  }) {
    final labelText = Text(
      label,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: emphasised ? 14 : 13,
        fontWeight: emphasised ? FontWeight.w700 : FontWeight.w500,
        color: emphasised
            ? context.appColors.textPrimary
            : context.appColors.textSecondary,
      ),
    );
    final valueText = Text(
      value,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: emphasised ? 15 : 13,
        fontWeight: emphasised ? FontWeight.w800 : FontWeight.w700,
        color: context.appColors.textPrimary,
      ),
    );
    // Large text stacks the amount under its label so words stay whole.
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: stacked
          ? SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [labelText, valueText],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: labelText),
                const SizedBox(width: 12),
                valueText,
              ],
            ),
    );
  }
}
