import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/firestore/property_ratings_aggregator.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';

// Compiled once instead of on every call.
final RegExp _kWhitespaceRe = RegExp(r'\s+');

class PropertyReviewsScreen extends StatefulWidget {
  const PropertyReviewsScreen({
    required this.property,
    this.rooms = const [],
    super.key,
  });

  final PropertyDoc property;
  final List<PropertyDoc> rooms;

  static Future<void> open(
    BuildContext context, {
    required PropertyDoc property,
    List<PropertyDoc> rooms = const [],
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PropertyReviewsScreen(
          property: property,
          rooms: rooms,
        ),
      ),
    );
  }

  @override
  State<PropertyReviewsScreen> createState() => _PropertyReviewsScreenState();
}

class _PropertyReviewsScreenState extends State<PropertyReviewsScreen> {
  bool _isLoading = true;
  List<_PropertyReviewItem> _reviews = [];
  double _avgRating = 0.0;
  int _totalCount = 0;
  final Map<int, int> _starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final p = widget.property;
    final targetIds = <String>{
      p.propertyId,
      if (p.parentPropertyId != null && p.parentPropertyId!.isNotEmpty)
        p.parentPropertyId!,
      for (final r in widget.rooms) r.propertyId,
    };

    try {
      final loaded = <_PropertyReviewItem>[];
      num totalStars = 0;
      final counts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

      final docsMap = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      final aggregatedDocs =
          await PropertyRatingsAggregator.fetchRatingDocsForProperty(
        firestore: FirebaseFirestore.instance,
        propertyId: p.propertyId,
        parentPropertyId: p.parentPropertyId,
        ownerId: p.ownerId,
        propertyName: p.propertyName,
        title: p.title,
        extraTargetIds: targetIds,
        forceRefresh: true,
      );
      for (final doc in aggregatedDocs) {
        docsMap[doc.id] = doc;
      }

      if (docsMap.isNotEmpty) {
        for (final doc in docsMap.values) {
          final rating = RatingDoc.fromSnapshot(doc);
          if (rating.raterRole != 'tenant') continue;
          final stars = rating.stars.toInt().clamp(1, 5);
          totalStars += stars;
          counts[stars] = (counts[stars] ?? 0) + 1;

          String raterName = 'Tenant';
          try {
            final userSnap = await FirebaseFirestore.instance
                .collection(FirestoreCollections.users)
                .doc(rating.raterId)
                .get();
            if (userSnap.exists) {
              final d = userSnap.data() ?? {};
              raterName =
                  '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
              if (raterName.isEmpty) raterName = 'Tenant';
            }
          } catch (_) {}

          String dateStr = 'Recent';
          final at = rating.createdAt?.toDate();
          if (at != null) {
            const months = [
              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
            ];
            dateStr = '${months[at.month - 1]} ${at.day}, ${at.year}';
          }

          String? unitLabel;
          if (widget.rooms.isNotEmpty && rating.propertyId != null) {
            final matched = widget.rooms.firstWhere(
              (r) => r.propertyId == rating.propertyId,
              orElse: () => p,
            );
            if (matched.roomName != null && matched.roomName!.isNotEmpty) {
              unitLabel = matched.roomName;
            }
          }

          loaded.add(
            _PropertyReviewItem(
              name: raterName,
              date: dateStr,
              stars: stars,
              comment: rating.review,
              unitLabel: unitLabel,
            ),
          );
        }
      }

      if (mounted) {
        if (loaded.isNotEmpty) {
          setState(() {
            _reviews = loaded;
            _totalCount = loaded.length;
            _avgRating = totalStars / loaded.length;
            _starCounts.addAll(counts);
            _isLoading = false;
          });
        } else {
          setState(() {
            _reviews = [];
            _totalCount = (p.totalRatings ?? 0).toInt();
            _avgRating = (p.effectiveAvgRating ?? p.avgRating?.toDouble() ?? 0.0);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading property ratings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final displayName = (p.propertyName?.trim().isNotEmpty ?? false)
        ? p.propertyName!.trim()
        : p.title;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.slate900,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Property Reviews',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.slate900,
          ),
        ),
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.fieldFill, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: _reviews.isEmpty
                  ? _buildEmptyState(displayName)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Property Info Pill Card ──────────────────────────
                          _buildPropertyBanner(displayName),
                          const SizedBox(height: 14),

                          // ── Rating Score Breakdown Card ──────────────────────
                          _buildRatingBreakdownCard(),
                          const SizedBox(height: 18),

                          // ── Reviews List Header ──────────────────────────────
                          Row(
                            children: [
                              Text(
                                'Tenant Reviews (${_reviews.length})',
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.slate900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Review Cards ─────────────────────────────────────
                          for (final review in _reviews) ...[
                            _buildReviewCard(review),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildPropertyBanner(String displayName) {
    final p = widget.property;
    final photo = p.isRoom
        ? (p.propertyCoverPhoto ??
            (p.photos.isNotEmpty ? p.photos.first : null))
        : (p.photos.isNotEmpty ? p.photos.first : null);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 58,
              height: 58,
              child: ListingImagePlaceholder(
                seed: p.propertyId.hashCode,
                photoUrl: photo,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.slate400,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        p.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBreakdownCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Big Score & Stars
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _avgRating > 0 ? _avgRating.toStringAsFixed(1) : '—',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: AppColors.slate900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final isFilled = i < _avgRating.round();
                    return Icon(
                      isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 20,
                      color: isFilled
                          ? AppColors.matchMedium
                          : AppColors.slate300,
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_totalCount ${_totalCount == 1 ? 'review' : 'reviews'}',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 90,
            width: 1,
            color: AppColors.fieldFill,
            margin: const EdgeInsets.symmetric(horizontal: 14),
          ),

          // Right: Star distribution bars
          Expanded(
            flex: 6,
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = _starCounts[star] ?? 0;
                final pct = _totalCount > 0 ? (count / _totalCount) : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: AppColors.matchMedium,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: AppColors.fieldFill,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.matchMedium,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 18,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate400,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(_PropertyReviewItem review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar initials
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  review.initials,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.name,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          review.date,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11.5,
                            color: AppColors.slate400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (review.unitLabel != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.fieldFill,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Stayed in ${review.unitLabel}',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 15,
                    color: i < review.stars
                        ? AppColors.matchMedium
                        : AppColors.slate300,
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!.trim(),
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                height: 1.45,
                color: AppColors.slate700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String displayName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.amberFill50,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.amberBorder200),
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                size: 36,
                color: AppColors.matchMedium,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No reviews yet',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reviews for $displayName will appear here once tenants complete their bookings.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13.5,
                color: AppColors.slate500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyReviewItem {
  const _PropertyReviewItem({
    required this.name,
    required this.date,
    required this.stars,
    this.comment,
    this.unitLabel,
  });

  final String name;
  final String date;
  final int stars;
  final String? comment;
  final String? unitLabel;

  String get initials {
    final parts = name.trim().split(_kWhitespaceRe);
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'T';
  }
}
