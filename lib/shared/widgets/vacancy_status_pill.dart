import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum VacancyStatus { available, pending, booked }

/// Colored pill showing the vacancy status of a property unit.
class VacancyStatusPill extends StatelessWidget {
  const VacancyStatusPill({required this.status, super.key});

  final VacancyStatus status;

  factory VacancyStatusPill.fromString(String value) {
    final s = switch (value.toLowerCase()) {
      'available' => VacancyStatus.available,
      'pending' => VacancyStatus.pending,
      _ => VacancyStatus.booked,
    };
    return VacancyStatusPill(status: s);
  }

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color textColor;
    final String label;

    switch (status) {
      case VacancyStatus.available:
        bg = AppColors.matchHigh;
        textColor = AppColors.onInk;
        label = 'Available';
      case VacancyStatus.pending:
        bg = AppColors.matchMedium;
        textColor = AppColors.onInk;
        label = 'Pending';
      case VacancyStatus.booked:
        bg = context.appColors.indicatorInactive;
        textColor = context.appColors.textSecondary;
        label = 'Booked';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
