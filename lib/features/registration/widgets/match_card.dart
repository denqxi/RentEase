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
    final cardContent = Container(
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
            color: AppColors.ink.withValues(alpha: 0.03),
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
              child: (match.imageUrl != null && match.imageUrl!.isNotEmpty)
                  ? Image.network(
                      match.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => match.imageAsset != null
                          ? Image.asset(
                              match.imageAsset!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _fallbackImage(context),
                            )
                          : _fallbackImage(context),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: context.appColors.fieldFill,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    )
                  : (match.imageAsset != null
                      ? Image.asset(
                          match.imageAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _fallbackImage(context),
                        )
                      : _fallbackImage(context)),
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
                    color: AppColors.ink.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (Rect bounds) => const LinearGradient(
                          colors: [
                            AppColors.destructive,
                            AppColors.matchMedium,
                            AppColors.amberBorder,
                            AppColors.matchHigh,
                            AppColors.primary,
                            AppColors.ownerPrimary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 10.5,
                          color: AppColors.onInk,
                        ),
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        '${match.scorePercent}% Match',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onInk,
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

    return cardContent;
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
