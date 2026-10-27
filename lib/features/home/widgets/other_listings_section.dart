
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore/models/models.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../matching/domain/entities/mismatch_reason.dart';
import '../cubit/home_cubit.dart';
import '../view/property_detail_screen.dart';
import 'listing_card_large.dart';

/// "Other listings": view-only listings that do not match all of the
/// tenant's saved preferences. Styled with the modern owner property card
/// layout to keep the home feed completely cohesive.
class OtherListingsSection extends StatelessWidget {
  const OtherListingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isGuest = context.select<HomeCubit, bool>((c) => c.state.isGuest);
    final othersFailed =
        context.select<HomeCubit, bool>((c) => c.state.othersFailed);
    final others = context.select<HomeCubit, List<Map<String, dynamic>>>(
      (c) => c.state.otherListings,
    );
    final savedIds =
        context.select<HomeCubit, Set<String>>((c) => c.state.savedIds);
    if (isGuest) return const SizedBox.shrink();

    if (othersFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                "Couldn't load other listings.",
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: context.read<HomeCubit>().retryOthers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (others.isEmpty) return const SizedBox.shrink();

    final cubit = context.read<HomeCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Other listings',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                  letterSpacing: -0.2,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Properties that may not meet all your preferences.',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: context.appColors.textSecondary,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              for (int i = 0; i < others.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                OtherListingCard(
                  property: others[i],
                  isSaved: savedIds.contains(others[i]['propertyId']),
                  onSavedToggle: () =>
                      cubit.toggleSaved(others[i]['propertyId'] as String),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      // Navigates instantly with in-memory map
                      builder: (_) => PropertyDetailScreen(
                        property: others[i],
                        homeCubit: cubit,
                        onPreferencesSaved: cubit.refresh,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// View-only card styled identically to modern owner property cards,
/// with amber mismatch badge, rating on top-right, 70% width address,
/// property type on bottom-left, and rent on bottom-right.
class OtherListingCard extends StatelessWidget {
  const OtherListingCard({
    required this.property,
    required this.onTap,
    this.isSaved = false,
    this.onSavedToggle,
    super.key,
  });

  final Map<String, dynamic> property;
  final VoidCallback onTap;
  final bool isSaved;
  final VoidCallback? onSavedToggle;

  static final RegExp _thousandsRe = RegExp(r'(\d)(?=(\d{3})+(?!\d))');

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(_thousandsRe, (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final id = (property['propertyId'] as String?) ?? '';
    final rent = (property['monthlyRent'] as num?)?.toInt() ?? 0;
    final reasons =
        (property['mismatchReasons'] as List?)?.cast<MismatchReason>() ??
        const <MismatchReason>[];
    final displayType = ((property['propertyType'] as String?)?.trim().isNotEmpty ?? false)
        ? (property['propertyType'] as String).trim()
        : 'Boarding House';
    final rawPhotos = property['photos'];
    final int photoCount = (rawPhotos is List && rawPhotos.isNotEmpty)
        ? rawPhotos.length
        : ((property['photoUrl'] as String?)?.isNotEmpty ?? false)
            ? 1
            : 1;

    final String rawTitle = (property['title'] as String?) ?? 'Property';
    final String? explicitProp = property['propertyName'] as String?;
    final String? explicitRoom = property['roomName'] as String?;
    final (propName, roomOrTitle) = ListingCardLarge.resolveTitles(
      rawTitle: rawTitle,
      explicitPropertyName: explicitProp,
      explicitRoomName: explicitRoom,
    );
    final String address = (property['address'] as String?) ?? '';
    final int seed = id.hashCode % 5 + 1;

    final docObj = property['propertyDoc'];
    final PropertyDoc? pDoc = docObj is PropertyDoc ? docObj : null;
    final avgRating = (property['rating'] as num?)?.toDouble() ??
        pDoc?.effectiveAvgRating ??
        (property['avgRating'] as num?)?.toDouble() ??
        (pDoc?.ratingSum != null && (pDoc?.totalRatings ?? 0) > 0
            ? (pDoc!.ratingSum! / pDoc.totalRatings!).toDouble()
            : null);
    final totalRatings = (property['totalRatings'] as num?)?.toInt() ??
        pDoc?.totalRatings?.toInt() ??
        (property['reviewCount'] as num?)?.toInt() ??
        0;
    final bool hasRating = avgRating != null && totalRatings > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate200, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Photo ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: SizedBox(
                  height: 155,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: ListingImagePlaceholder(
                          seed: seed,
                          photoUrl: property['photoUrl'] as String?,
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.slate200.withValues(alpha: 0.7),
                                width: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Top-left: Mismatch warning badge (white pill with shadow)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7.5,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.slate900.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 11,
                                color: AppColors.amberPrimary,
                              ),
                              SizedBox(width: 3.5),
                              Text(
                                "Doesn't match",
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate900,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Top-right: Like / Heart button (white circle with shadow)
                      if (onSavedToggle != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Material(
                            color: AppColors.transparent,
                            child: InkWell(
                              onTap: onSavedToggle,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.slate900.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  isSaved ? Icons.favorite : Icons.favorite_border,
                                  color: isSaved
                                      ? AppColors.destructive
                                      : AppColors.slate600,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Bottom-right: Photo count badge (clean white pill)
                      if (photoCount > 0)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.slate900.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_outlined,
                                  size: 11,
                                  color: AppColors.slate600,
                                ),
                                const SizedBox(width: 3.5),
                                Text(
                                  '$photoCount',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Details ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (propName != null) ...[
                      // Property / Building name (sub-header above room name)
                      Text(
                        propName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate700,
                          letterSpacing: -0.1,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],

                    // Prominent row: Room Name on left (or full title if not a room), Rating on right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            roomOrTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 18.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              letterSpacing: -0.3,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 15.5,
                              color: AppColors.matchMedium,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              hasRating ? avgRating.toStringAsFixed(1) : '0',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate900,
                              ),
                            ),
                            if (hasRating && totalRatings > 0) ...[
                              const SizedBox(width: 2),
                              Text(
                                '($totalRatings)',
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Address row: restricted to 70% width
                    FractionallySizedBox(
                      widthFactor: 0.70,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.slate400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (reasons.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 13,
                            color: AppColors.matchMedium,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              reasons.take(2).map((r) => r.shortLabel).join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.amberText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (propName == null) const SizedBox(height: 16.5),
                    const SizedBox(height: 8),
                    const Divider(
                      height: 1,
                      thickness: 0.8,
                      color: AppColors.fieldFill,
                    ),
                    const SizedBox(height: 8),

                    // Bottom row: Property Type on left, Rent on right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Property Type with SVG icon
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const AppSvgIcon(
                              svgString: AppSvgIcons.propertyType,
                              size: 15,
                              color: AppColors.slate900,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              displayType,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate900,
                              ),
                            ),
                          ],
                        ),

                        // Right: Rent
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '₱${_fmt(rent)}',
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const TextSpan(
                                text: ' / month',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
