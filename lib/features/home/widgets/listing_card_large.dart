import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../model/listing.dart';

/// Large card matching the modern owner property card styling (`_ModernPropertyCard`),
/// customized for tenants with match badge and heart action.
class ListingCardLarge extends StatelessWidget {
  const ListingCardLarge({
    required this.listing,
    required this.onSavedToggle,
    this.isGuest = false,
    this.onTap,
    super.key,
  });

  final Listing listing;
  final VoidCallback onSavedToggle;
  final bool isGuest;
  final VoidCallback? onTap;

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  /// Resolves the property name and prominent title (room name or property title).
  ///
  /// Eliminates hyphens/dashes between building and room, positioning the property
  /// name cleanly as a sub-header and making the room name prominent.
  static (String? propName, String roomOrTitle) resolveTitles({
    required String rawTitle,
    String? explicitPropertyName,
    String? explicitRoomName,
  }) {
    // 1. If explicit roomName is provided and non-empty:
    if (explicitRoomName != null && explicitRoomName.trim().isNotEmpty) {
      final room = explicitRoomName.trim();
      final prop = (explicitPropertyName != null && explicitPropertyName.trim().isNotEmpty)
          ? explicitPropertyName.trim()
          : rawTitle.replaceAll(RegExp(r'\s*[—–-]\s*' + RegExp.escape(room)), '').trim();
      return (prop.isNotEmpty && prop.toLowerCase() != room.toLowerCase() ? prop : null, room);
    }

    // 2. If explicit propertyName is provided and rawTitle contains it + room:
    if (explicitPropertyName != null && explicitPropertyName.trim().isNotEmpty) {
      final prop = explicitPropertyName.trim();
      final regex = RegExp(r'^' + RegExp.escape(prop) + r'\s*[—–-]\s*(.+)$', caseSensitive: false);
      final match = regex.firstMatch(rawTitle.trim());
      if (match != null) {
        final room = match.group(1)!.trim();
        if (room.isNotEmpty) {
          return (prop, room);
        }
      }
    }

    // 3. Fallback: Parse common hyphen / en-dash / em-dash delimiters in rawTitle:
    // e.g. "Lucky Boarding House — Room 101" or "Lucky Boarding House – Room 101" or "Lucky Boarding House - Room 101"
    final dashMatch = RegExp(r'^(.+?)\s+[—–-]\s+(.+)$').firstMatch(rawTitle.trim());
    if (dashMatch != null) {
      final part1 = dashMatch.group(1)!.trim();
      final part2 = dashMatch.group(2)!.trim();
      if (part1.isNotEmpty && part2.isNotEmpty) {
        return (part1, part2);
      }
    }

    return (null, rawTitle.trim());
  }

  @override
  Widget build(BuildContext context) {
    final displayType = (listing.propertyType?.trim().isNotEmpty ?? false)
        ? listing.propertyType!.trim()
        : 'Boarding House';
    final int photoCount =
        listing.photos.isNotEmpty ? listing.photos.length : 1;
    final bool hasRating =
        listing.rating != null && (listing.reviewCount ?? 0) > 0;

    final (propName, roomOrTitle) = resolveTitles(
      rawTitle: listing.title,
      explicitPropertyName: listing.propertyName ?? listing.propertyDoc?.propertyName,
      explicitRoomName: listing.roomName ?? listing.propertyDoc?.roomName,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
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
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        child: ListingImagePlaceholder(
                          seed: listing.imageSeed,
                          photoUrl: listing.photoUrl,
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0)
                                    .withValues(alpha: 0.7),
                                width: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Top-left: Match score pill (transparent glass, subtle outline, smaller)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (!isGuest && listing.matchPercent > 0)
                                      ? listing.matchDotColor.withValues(alpha: 0.45)
                                      : Colors.white.withValues(alpha: 0.25),
                                  width: 0.6,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isGuest && listing.matchPercent > 0) ...[
                                    Text(
                                      '${listing.matchPercent}% Match',
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ] else ...[
                                    const Icon(
                                      Icons.lock_outline,
                                      size: 9.5,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 3),
                                    const Text(
                                      'Match',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Top-right: Like / Heart button (moved to top-right, smaller)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _HeartButton(
                          isSaved: listing.isSaved,
                          onTap: onSavedToggle,
                        ),
                      ),

                      // Bottom-right: Photo count badge (transparent glass badge)
                      if (photoCount > 0)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.5,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 0.6,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.photo_outlined,
                                      size: 10.5,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3.5),
                                    Text(
                                      '$photoCount',
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                          color: Color(0xFF334155),
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
                              color: Color(0xFF0F172A),
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
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              hasRating
                                  ? listing.rating!.toStringAsFixed(1)
                                  : '0',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (hasRating && (listing.reviewCount ?? 0) > 0) ...[
                              const SizedBox(width: 2),
                              Text(
                                '(${listing.reviewCount})',
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
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
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              listing.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (propName == null) const SizedBox(height: 16.5),
                    const SizedBox(height: 8),
                    const Divider(
                      height: 1,
                      thickness: 0.8,
                      color: Color(0xFFF1F5F9),
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
                              color: Color(0xFF0F172A),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              displayType,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),

                        // Right: Rent
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '₱${_fmt(listing.pricePerMonth)}',
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
                                  color: Color(0xFF64748B),
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

class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.isSaved, required this.onTap});

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 0.6,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? AppColors.destructive : Colors.white,
                size: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
