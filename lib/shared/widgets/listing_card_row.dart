import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/home/model/listing.dart';
import 'listing_image_placeholder.dart';
import 'match_badge.dart';

/// Horizontal row card for a listing — used in Nearby, Matches, and Saved.
class ListingCardRow extends StatelessWidget {
  const ListingCardRow({
    required this.listing,
    required this.onSavedToggle,
    this.onTap,
    super.key,
  });

  final Listing listing;
  final VoidCallback onSavedToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.field),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: <Widget>[
            _Thumbnail(listing: listing, onSavedToggle: onSavedToggle),
            SizedBox(width: AppSpacing.md),
            Expanded(child: _Info(listing: listing)),
          ],
        ),
      ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.listing, required this.onSavedToggle});

  final Listing listing;
  final VoidCallback onSavedToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 80,
      child: Stack(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.chip),
            child: ListingImagePlaceholder(seed: listing.imageSeed),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            child: MatchBadge(percent: listing.matchPercent),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _HeartButton(
              isSaved: listing.isSaved,
              onTap: onSavedToggle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                listing.title,
                style: AppTextStyles.label(context).copyWith(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              '\$${listing.pricePerMonth.toLocale()}',
              style: AppTextStyles.label(context).copyWith(
                color: AppColors.accent,
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            Icon(
              Icons.location_on_outlined,
              size: 12,
              color: context.appColors.textSecondary,
            ),
            SizedBox(width: 2),
            Expanded(
              child: Text(
                listing.location,
                style: AppTextStyles.caption(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            Icon(Icons.bed, size: 12, color: context.appColors.textSecondary),
            SizedBox(width: 2),
            Text('${listing.beds} bd', style: AppTextStyles.caption(context)),
            SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.bathroom_outlined,
              size: 12,
              color: context.appColors.textSecondary,
            ),
            SizedBox(width: 2),
            Text('${listing.baths} ba', style: AppTextStyles.caption(context)),
          ],
        ),
      ],
    );
  }
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.isSaved, required this.onTap});

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSaved ? Icons.favorite : Icons.favorite_border,
          color: isSaved ? AppColors.accent : context.appColors.textSecondary,
          size: 14,
        ),
      ),
    );
  }
}

extension on int {
  /// Formats an integer with comma separators (e.g. 1800 → "1,800").
  String toLocale() {
    return toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
