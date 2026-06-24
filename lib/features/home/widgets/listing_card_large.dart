import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../../shared/widgets/match_badge.dart';
import '../model/listing.dart';

/// Large card used in the "Recommended for you" horizontal scroll.
class ListingCardLarge extends StatelessWidget {
  const ListingCardLarge({
    required this.listing,
    required this.onSavedToggle,
    super.key,
  });

  final Listing listing;
  final VoidCallback onSavedToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
      height: 158,
      child: Stack(
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.card),
            ),
            child: ListingImagePlaceholder(seed: listing.imageSeed),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: MatchBadge(
              percent: listing.matchPercent,
              showLabel: true,
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  listing.title,
                  style: AppTextStyles.label.copyWith(fontSize: 13),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '\$${_fmt(listing.pricePerMonth)}/mo',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.accent,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              const Icon(
                Icons.location_on_outlined,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  listing.location,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _Stats(listing: listing),
        ],
      ),
    );
  }

  String _fmt(int value) => value
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _Stats extends StatelessWidget {
  const _Stats({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.bed, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 2),
        Text('${listing.beds} bd', style: AppTextStyles.caption),
        const SizedBox(width: AppSpacing.sm),
        const Icon(
          Icons.bathroom_outlined,
          size: 12,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 2),
        Text('${listing.baths} ba', style: AppTextStyles.caption),
        if (listing.sqft != null) ...<Widget>[
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.crop_free,
            size: 12,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 2),
          Text('${listing.sqft} ft²', style: AppTextStyles.caption),
        ],
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSaved ? Icons.favorite : Icons.favorite_border,
          color: isSaved ? AppColors.accent : AppColors.textSecondary,
          size: 17,
        ),
      ),
    );
  }
}
