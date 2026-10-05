import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/guest_access_sheet.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../../shared/widgets/match_badge.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../registration/model/user_role.dart';
import '../../shell/cubit/shell_cubit.dart';
import '../cubit/home_cubit.dart';
import '../model/listing.dart';
import '../view/property_detail_screen.dart';

/// Fetches the real detail map (owner info included) before navigating —
/// shared by both the "Recommended" and "Compatible properties" sections.
Future<void> openPropertyDetail(
  BuildContext context,
  HomeCubit cubit,
  String propertyId,
) async {
  final detail = await cubit.loadPropertyDetail(propertyId);
  if (!context.mounted) return;
  if (detail == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This listing is no longer available.')),
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PropertyDetailScreen(
        property: detail,
        isGuest: cubit.state.isGuest,
        homeCubit: cubit,
        onPreferencesSaved: cubit.refresh,
      ),
    ),
  );
}

/// "Compatible properties" vertical list section on the home screen — sorted
/// by TOPSIS Ci score, never by distance alone (CLAUDE.md rule 9).
class NearbySection extends StatelessWidget {
  const NearbySection({super.key});

  @override
  Widget build(BuildContext context) {
    final listings = context.select<HomeCubit, List<Listing>>(
      (c) => c.state.nearby,
    );
    final cubit = context.read<HomeCubit>();
    final isGuest = context.select<ProfileCubit, bool>(
      (c) => c.state.userRole == UserRole.guest,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: <Widget>[
              Text(
                isGuest ? 'Newest listings' : 'Compatible properties',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    context.read<ShellCubit>().selectTab(ShellTab.search),
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
        if (isGuest)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              0,
            ),
            child: Text(
              'Sign up to see your matches',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: context.appColors.textSecondary,
              ),
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
            isGuest: isGuest,
            onSavedToggle: () {
              if (isGuest) {
                GuestAccessSheet.show(ctx);
                return;
              }
              cubit.toggleSaved(listings[i].id);
            },
            onTap: () => openPropertyDetail(ctx, cubit, listings[i].id),
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
    this.isGuest = false,
    this.onTap,
  });

  final Listing listing;
  final VoidCallback onSavedToggle;
  final bool isGuest;
  final VoidCallback? onTap;

  String _fmt(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

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
              color: AppColors.scrim.withValues(alpha: 0.06),
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
                    child: ListingImagePlaceholder(
                      seed: listing.imageSeed,
                      photoUrl: listing.photoUrl,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: MatchBadge(
                        percent: listing.matchPercent,
                        isLocked: isGuest,
                      ),
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
