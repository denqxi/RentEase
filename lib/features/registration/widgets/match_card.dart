import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../model/match_result.dart';

/// Card summarising a top listing match on the success screen with a property
/// thumbnail, match percent badge, location, and monthly price.
class MatchCard extends StatelessWidget {
  const MatchCard({required this.match, super.key});

  final MatchResult match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.appColors.fieldBorder.withValues(alpha: 0.9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Property Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 90,
              height: 90,
              child: match.imageAsset != null
                  ? Image.asset(
                      match.imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallbackImage(context),
                    )
                  : _fallbackImage(context),
            ),
          ),
          const SizedBox(width: 14),

          // Listing Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Percent Match Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.5,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (Rect bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFF3366), // vibrant pink/rose
                            Color(0xFFFF9900), // vivid orange
                            Color(0xFFFFDD00), // bright yellow
                            Color(0xFF00E676), // neon green
                            Color(0xFF00D2FF), // cyan / bright blue
                            Color(0xFF9D00FF), // vivid violet
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 10.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        '${match.scorePercent}% Match',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Property Title
                Text(
                  match.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),

                // Location with Map Pin
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
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
                          fontWeight: FontWeight.w400,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Price
                Text(
                  match.price ?? '₱8,500/mo',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage(BuildContext context) {
    return Container(
      color: context.appColors.fieldFill,
      alignment: Alignment.center,
      child: Icon(
        Icons.home_work_outlined,
        color: context.appColors.hint,
        size: 32,
      ),
    );
  }
}
