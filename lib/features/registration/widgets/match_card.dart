import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../model/match_result.dart';

/// Highlighted property card summarising a top match with comfortable height,
/// thumbnail, compatibility score badge, property title, and light blue price.
class MatchCard extends StatelessWidget {
  const MatchCard({required this.match, super.key});

  final MatchResult match;

  Color _getIndicatorColor(int score) {
    if (score >= 95) {
      return const Color(0xFF22C55E); // Green
    } else if (score >= 90) {
      return const Color(0xFFF59E0B); // Yellow / Amber
    } else {
      return const Color(0xFFEF4444); // Subtle light red
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicatorColor = _getIndicatorColor(match.scorePercent);
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 720 || mediaQuery.size.width < 360;
    final imageSize = isCompact ? 80.0 : 90.0;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12.0 : 14.0),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: context.appColors.fieldBorder.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // ── Thumbnail Image with Border & Shadow ──────────────────────────
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.appColors.fieldBorder,
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: SizedBox(
                width: imageSize,
                height: imageSize,
                child: Image.asset(
                  match.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.accentSoft,
                    child: const Icon(
                      Icons.home_rounded,
                      color: AppColors.accent,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // ── Details ───────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Match percentage badge (Low opacity black bg, white %, colored icon)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 11,
                        color: indicatorColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${match.scorePercent}% Match',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),

                // Property Name
                Text(
                  match.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: isCompact ? 14.5 : 15.5,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),

                // Address Subheader with location pin icon
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: context.appColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        match.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Price (Light Blue / Brand Cyan Teal)
                Text(
                  match.price,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: isCompact ? 13.5 : 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1ABCCE), // Light blue
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
