import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../../shared/widgets/match_badge.dart';
import '../model/listing.dart';

/// Large card used in the "Recommended for you" horizontal scroll.
/// 220 wide x 270 tall; image area 155px with gradient overlay.
class ListingCardLarge extends StatelessWidget {
  const ListingCardLarge({
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
        width: 220,
        height: 270,
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Photo(listing: listing, onSavedToggle: onSavedToggle),
            _Details(listing: listing),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.listing, required this.onSavedToggle});

  final Listing listing;
  final VoidCallback onSavedToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 155,
      child: Stack(
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox.expand(
              child: ListingImagePlaceholder(seed: listing.imageSeed),
            ),
          ),
          // Gradient overlay bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Match badge top-left
          Positioned(
            top: 10,
            left: 10,
            child: MatchBadge(
              percent: listing.matchPercent,
              showLabel: true,
            ),
          ),
          // Heart top-right
          Positioned(
            top: 8,
            right: 8,
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

class _Details extends StatelessWidget {
  const _Details({required this.listing});

  final Listing listing;

  String _fmt(int value) => value
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm + 2,
        AppSpacing.sm,
        AppSpacing.sm + 2,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            listing.title,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '₱${_fmt(listing.pricePerMonth)}/mo',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
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
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: context.appColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSaved ? Icons.favorite : Icons.favorite_border,
          color: isSaved ? AppColors.accent : context.appColors.textSecondary,
          size: 17,
        ),
      ),
    );
  }
}
