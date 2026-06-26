import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum AppChipVariant { saved, session, owner }

/// Chip widget with saved / session / owner color variants.
///
/// Height 28 px, border radius 20 px, horizontal padding 10 px.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    required this.variant,
    this.isLocked = false,
    this.onRemove,
    super.key,
  });

  final String label;
  final AppChipVariant variant;

  /// Shows a lock icon when true.
  final bool isLocked;

  /// Shows an X button when non-null.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color fg;

    switch (variant) {
      case AppChipVariant.saved:
        bg = AppColors.tenantFillBlue;
        border = AppColors.primaryMid;
        fg = AppColors.tenantTextDeep;
      case AppChipVariant.session:
        bg = AppColors.amberFill;
        border = AppColors.amberBorder;
        fg = AppColors.amberText;
      case AppChipVariant.owner:
        bg = AppColors.ownerFill;
        border = AppColors.ownerPrimary;
        fg = AppColors.ownerText;
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLocked) ...[
            Icon(Icons.lock_outline, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 12, color: fg),
            ),
          ],
        ],
      ),
    );
  }
}
