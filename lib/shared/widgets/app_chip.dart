import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum AppChipVariant { saved, session, owner }

/// Styled chip supporting saved (teal), session (amber), and owner (ink) variants.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    this.variant = AppChipVariant.saved,
    this.isLocked = false,
    this.onRemove,
    super.key,
  });

  final String label;
  final AppChipVariant variant;
  final bool isLocked;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLocked) ...[
            Icon(Icons.lock_rounded, size: 10, color: textColor),
            SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
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
            ),
          ],
        ],
      ),
    );
  }
}
