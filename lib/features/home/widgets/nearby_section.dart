import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
<<<<<<< Updated upstream
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/listing_card_row.dart';
=======
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../../shared/widgets/match_badge.dart';
>>>>>>> Stashed changes
import '../cubit/home_cubit.dart';
import '../model/listing.dart';
import '../view/property_detail_screen.dart';

/// "Nearby homes" vertical list section on the home screen.
class NearbySection extends StatelessWidget {
  const NearbySection({super.key});

  @override
  Widget build(BuildContext context) {
    final listings =
        context.select<HomeCubit, List<Listing>>((c) => c.state.nearby);
    final cubit = context.read<HomeCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: <Widget>[
              Text(
                'Compatible properties',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: listings.length,
          separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
          itemBuilder: (ctx, i) => _NearbyCard(
            listing: listings[i],
            onSavedToggle: () => cubit.toggleSaved(listings[i].id),
            onTap: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                builder: (_) => PropertyDetailScreen(
<<<<<<< Updated upstream
                  property: MockData.properties[i % MockData.properties.length],
=======
                  property:
                      MockData.properties[i % MockData.properties.length],
>>>>>>> Stashed changes
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({
    required this.listing,
    required this.onSavedToggle,
    this.onTap,
  });

  final Listing listing;
  final VoidCallback onSavedToggle;
  final VoidCallback? onTap;

  String _fmt(int value) => value
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        child: Row(
          children: <Widget>[
            // Thumbnail 72x72 with match badge overlay
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListingImagePlaceholder(seed: listing.imageSeed),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: MatchBadge(percent: listing.matchPercent),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    listing.title,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3),
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
                  SizedBox(height: 3),
                  Text(
                    '₱${_fmt(listing.pricePerMonth)}/mo',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
