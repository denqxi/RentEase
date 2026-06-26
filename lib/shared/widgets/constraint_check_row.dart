import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// A single row showing a constraint check result.
///
/// Passing: teal checkmark, primary text. Failing: amber warning, amber value.
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
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 36,
          child: Row(
            children: [
              Icon(
                isPassing
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
                size: 16,
                color: isPassing ? AppColors.primaryTeal : AppColors.amberPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPassing ? AppColors.textPrimary : AppColors.amberPrimary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
