
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../model/listing.dart';

/// Large card matching the modern owner property card styling (`_ModernPropertyCard`),
/// customized for tenants with match badge and heart action.
class ListingCardLarge extends StatefulWidget {
  const ListingCardLarge({
    required this.listing,
    required this.onSavedToggle,
    this.isGuest = false,
    this.onTap,
    this.rank,
    super.key,
  });

  final Listing listing;
  final VoidCallback onSavedToggle;
  final bool isGuest;
  final VoidCallback? onTap;
  final int? rank;

  static final RegExp _thousandsRe = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
  static final RegExp _dashRe = RegExp(r'^(.+?)\s+[—–-]\s+(.+)$');

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(_thousandsRe, (m) => '${m[1]},');

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
    final dashMatch = _dashRe.firstMatch(rawTitle.trim());
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
  State<ListingCardLarge> createState() => _ListingCardLargeState();
}

class _ListingCardLargeState extends State<ListingCardLarge> {
  bool _isAddressExpanded = false;

  // Rating comes from the counters on the listing's property doc (no extra
  // per-card reads); an unrated or legacy listing shows no rating.

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final onSavedToggle = widget.onSavedToggle;
    final isGuest = widget.isGuest;
    final onTap = widget.onTap;

    final displayType = (listing.propertyType?.trim().isNotEmpty ?? false)
        ? listing.propertyType!.trim()
        : 'Boarding House';
    final int photoCount =
        listing.photos.isNotEmpty ? listing.photos.length : 1;
    final double? effectiveRating = listing.rating ??
        listing.propertyDoc?.effectiveAvgRating ??
        listing.propertyDoc?.avgRating?.toDouble();
    final int effectiveReviewCount = listing.reviewCount ??
        listing.propertyDoc?.totalRatings?.toInt() ??
        0;
    final bool hasRating =
        effectiveRating != null && effectiveRating > 0 && effectiveReviewCount > 0;

    final (propName, roomOrTitle) = ListingCardLarge.resolveTitles(
      rawTitle: listing.title,
      explicitPropertyName: listing.propertyName ?? listing.propertyDoc?.propertyName,
      explicitRoomName: listing.roomName ?? listing.propertyDoc?.roomName,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isBounded = constraints.hasBoundedHeight;

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
                mainAxisSize: isBounded ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  // ── Hero Photo (12px top padding) ─────────────────────────
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
                                    color: AppColors.slate200
                                        .withValues(alpha: 0.7),
                                    width: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Top-left: Match score pill & Rank badge (clean white pill with soft shadow)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
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
                                  if (widget.rank != null &&
                                      widget.rank! >= 1 &&
                                      widget.rank! <= 3) ...[
                                    if (widget.rank == 1)
                                      const _CrownIcon(
                                        color: AppColors.rankGold,
                                        size: 14,
                                      )
                                    else if (widget.rank == 2)
                                      const Icon(
                                        Icons.workspace_premium_rounded,
                                        size: 15,
                                        color: AppColors.slate400,
                                      )
                                    else
                                      const Icon(
                                        Icons.workspace_premium_rounded,
                                        size: 15,
                                        color: AppColors.rankBronze,
                                      ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '#${widget.rank} Top Match',
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.slate900,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 1,
                                      height: 11,
                                      color: AppColors.slate300,
                                    ),
                                    const SizedBox(width: 6),
                                  ] else if (!isGuest && listing.matchPercent > 0) ...[
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 12,
                                      color: listing.matchDotColor,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  if (!isGuest && listing.matchPercent > 0)
                                    Text(
                                      '${listing.matchPercent}% Match',
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.slate900,
                                        letterSpacing: -0.1,
                                      ),
                                    )
                                  else ...[
                                    if (widget.rank == null) ...[
                                      const Icon(
                                        Icons.lock_outline,
                                        size: 11.5,
                                        color: AppColors.slate500,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    const Text(
                                      'Match',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.slate900,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Top-right: Like / Heart button
                          Positioned(
                            top: 10,
                            right: 10,
                            child: _HeartButton(
                              isSaved: listing.isSaved,
                              onTap: onSavedToggle,
                            ),
                          ),

                          // Bottom-right: Photo count badge (clean white pill)
                          if (photoCount > 0)
                            Positioned(
                              bottom: 8,
                              right: 8,
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.photo_outlined,
                                      size: 12,
                                      color: AppColors.slate600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$photoCount',
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.slate900,
                                        letterSpacing: -0.1,
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

                  // ── Details (12px bottom padding to match 12px top padding) ─
                  if (isBounded)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: _buildDetailsContent(
                          propName: propName,
                          roomOrTitle: roomOrTitle,
                          hasRating: hasRating,
                          effectiveRating: effectiveRating,
                          effectiveReviewCount: effectiveReviewCount,
                          listing: listing,
                          displayType: displayType,
                          isBounded: isBounded,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: _buildDetailsContent(
                        propName: propName,
                        roomOrTitle: roomOrTitle,
                        hasRating: hasRating,
                        effectiveRating: effectiveRating,
                        effectiveReviewCount: effectiveReviewCount,
                        listing: listing,
                        displayType: displayType,
                        isBounded: isBounded,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsContent({
    required String? propName,
    required String roomOrTitle,
    required bool hasRating,
    required double? effectiveRating,
    required int effectiveReviewCount,
    required Listing listing,
    required String displayType,
    required bool isBounded,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: isBounded ? MainAxisSize.max : MainAxisSize.min,
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
                  hasRating
                      ? effectiveRating!.toStringAsFixed(1)
                      : '0',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
                if (hasRating && effectiveReviewCount > 0) ...[
                  const SizedBox(width: 2),
                  Text(
                    '($effectiveReviewCount)',
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

        // Address row: constrained to 70% width, tap to expand full address
        FractionallySizedBox(
          widthFactor: 0.70,
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _isAddressExpanded = !_isAddressExpanded;
              });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1.5),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 13,
                    color: AppColors.slate400,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topLeft,
                    child: Text(
                      listing.location,
                      maxLines: _isAddressExpanded ? (isBounded ? 2 : null) : 1,
                      overflow: _isAddressExpanded
                          ? (isBounded ? TextOverflow.ellipsis : TextOverflow.visible)
                          : TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Space below address (uncluttered) & pushes footer to bottom
        if (isBounded) ...[
          SizedBox(height: _isAddressExpanded ? 2 : 8),
          const Spacer(),
        ] else
          const SizedBox(height: 12),

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
                    text: '₱${ListingCardLarge._fmt(listing.pricePerMonth)}',
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
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
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
            color: isSaved ? AppColors.destructive : AppColors.slate600,
            size: 18,
          ),
        ),
      ),
    );
  }
}


class _CrownIcon extends StatelessWidget {
  const _CrownIcon({required this.color, this.size = 13});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.82),
      painter: _CrownPainter(color: color),
    );
  }
}

class _CrownPainter extends CustomPainter {
  _CrownPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;
    final path = Path();
    // 3-point crown with dots/points matching the design reference
    path.moveTo(0, h * 0.22);
    path.lineTo(w * 0.28, h * 0.58);
    path.lineTo(w * 0.50, 0);
    path.lineTo(w * 0.72, h * 0.58);
    path.lineTo(w, h * 0.22);
    path.lineTo(w * 0.88, h * 0.82);
    path.lineTo(w * 0.12, h * 0.82);
    path.close();

    canvas.drawPath(path, paint);

    // Bottom base bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.88, w * 0.84, h * 0.14),
        const Radius.circular(1),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CrownPainter oldDelegate) =>
      oldDelegate.color != color;
}
