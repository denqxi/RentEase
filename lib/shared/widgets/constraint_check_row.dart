import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// A row showing a constraint label and value with a pass/fail indicator.
class ConstraintCheckRow extends StatelessWidget {
  const ConstraintCheckRow({
    required this.label,
    required this.value,
    required this.isPassing,
    super.key,
  });

  final String label;
  final String value;
  final bool isPassing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Icon(
                isPassing ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: isPassing ? AppColors.matchHigh : AppColors.matchMedium,
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPassing ? context.appColors.textPrimary : AppColors.matchMedium,
                ),
              ),
            ],
          ),
        ),
        Divider(color: context.appColors.fieldBorder, thickness: 0.5, height: 1),
      ],
    );
  }
}
