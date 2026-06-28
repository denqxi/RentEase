import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum AppChipVariant { saved, session, owner }

<<<<<<< Updated upstream
/// Chip widget with saved / session / owner color variants.
///
/// Height 28 px, border radius 20 px, horizontal padding 10 px.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    required this.variant,
=======
/// Styled chip supporting saved (teal), session (amber), and owner (ink) variants.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    this.variant = AppChipVariant.saved,
>>>>>>> Stashed changes
    this.isLocked = false,
    this.onRemove,
    super.key,
  });

  final String label;
  final AppChipVariant variant;
<<<<<<< Updated upstream

  /// Shows a lock icon when true.
  final bool isLocked;

  /// Shows an X button when non-null.
=======
  final bool isLocked;
>>>>>>> Stashed changes
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
<<<<<<< Updated upstream
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
=======
    final Color textColor;

    switch (variant) {
      case AppChipVariant.saved:
        bg = AppColors.accentSoft;
        border = AppColors.accent;
        textColor = AppColors.accent;
      case AppChipVariant.session:
        bg = const Color(0xFFFEF3C7);
        border = AppColors.matchMedium;
        textColor = AppColors.matchMedium;
      case AppChipVariant.owner:
        bg = context.appColors.fieldFill;
        border = context.appColors.ink;
        textColor = context.appColors.ink;
    }

    return Container(
      height: 30,
>>>>>>> Stashed changes
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
<<<<<<< Updated upstream
        border: Border.all(color: border, width: 0.5),
=======
        border: Border.all(color: border),
>>>>>>> Stashed changes
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLocked) ...[
<<<<<<< Updated upstream
            Icon(Icons.lock_outline, size: 11, color: fg),
            const SizedBox(width: 4),
=======
            Icon(Icons.lock_rounded, size: 10, color: textColor),
            SizedBox(width: 4),
>>>>>>> Stashed changes
          ],
          Text(
            label,
            style: TextStyle(
<<<<<<< Updated upstream
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
=======
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          if (onRemove != null) ...[
            SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close_rounded, size: 10, color: textColor),
>>>>>>> Stashed changes
            ),
          ],
        ],
      ),
    );
  }
}
