import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

<<<<<<< Updated upstream
/// A single row showing a constraint check result.
///
/// Passing: teal checkmark, primary text. Failing: amber warning, amber value.
=======
/// A row showing a constraint label and value with a pass/fail indicator.
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
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
=======
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
>>>>>>> Stashed changes
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
<<<<<<< Updated upstream
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPassing ? AppColors.textPrimary : AppColors.amberPrimary,
=======
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPassing ? context.appColors.textPrimary : AppColors.matchMedium,
>>>>>>> Stashed changes
                ),
              ),
            ],
          ),
        ),
<<<<<<< Updated upstream
        const Divider(height: 1, color: AppColors.border),
=======
        Divider(color: context.appColors.fieldBorder, thickness: 0.5, height: 1),
>>>>>>> Stashed changes
      ],
    );
  }
}
