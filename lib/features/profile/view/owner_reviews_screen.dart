import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/cubit/app_theme_cubit.dart';
import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/firestore/property_ratings_aggregator.dart';

class OwnerReviewsScreen extends StatefulWidget {
  const OwnerReviewsScreen({super.key});


  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ];

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const OwnerReviewsScreen(),
        ),
      );

  @override
  State<OwnerReviewsScreen> createState() => _OwnerReviewsScreenState();
}

class _OwnerReviewsScreenState extends State<OwnerReviewsScreen> {
  bool _isLoading = true;
  List<_ReviewItem> _reviews = [];
  double _avgRating = 0.0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final ownerEntries =
            await PropertyRatingsAggregator.fetchRatingDocsForOwner(
          firestore: FirebaseFirestore.instance,
          ownerId: uid,
          forceRefresh: true,
        );

        if (ownerEntries.isNotEmpty) {
          final loaded = <_ReviewItem>[];
          num totalStars = 0;

          for (final entry in ownerEntries) {
            final rating = RatingDoc.fromSnapshot(entry.doc);
            totalStars += rating.stars;

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

            loaded.add(
              _ReviewItem(
                name: raterName,
                date: dateStr,
                stars: rating.stars.toInt(),
                comment: rating.review,
                propertyTitle: entry.propertyTitle,
              ),
            );
          }

          if (mounted) {
            setState(() {
              _reviews = loaded;
              _totalCount = loaded.length;
              _avgRating = (totalStars / loaded.length);
              _isLoading = false;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('Error loading ratings: $e');
      }
    }

    if (mounted) {
      setState(() {
        _reviews = [];
        _avgRating = 0.0;
        _totalCount = 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppThemeCubit>().state;
    final bgColor = isDark ? context.appColors.surface : AppColors.surface;
    final cardColor = isDark ? AppColors.darkCard : AppColors.surface;
    final textColor = isDark ? AppColors.surface : AppColors.ink;

    final isShowingEmpty = _reviews.isEmpty;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                  boxShadow: OwnerReviewsScreen.cardShadow,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: textColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'My reviews',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: isShowingEmpty
                  ? _buildEmptyState(textColor)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 14),

                          // Top Summary Card (Soft shadow, no border)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 26,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: OwnerReviewsScreen.cardShadow,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _avgRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    return const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 2),
                                      child: Icon(
                                        Icons.star_rounded,
                                        size: 26,
                                        color: AppColors.matchMedium,
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Total across your properties ($_totalCount ${_totalCount == 1 ? 'review' : 'reviews'})',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13,
                                    color: AppColors.slate500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Reviews list
                          for (final review in _reviews) ...[
                            _buildReviewCard(review, cardColor, textColor),
                            const SizedBox(height: 12),
                          ],

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildReviewCard(_ReviewItem review, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: OwnerReviewsScreen.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.name,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Text(
                review.date,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  color: AppColors.slate400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Star rating + Property badge
          Row(
            children: [
              ...List.generate(5, (index) {
                final isFilled = index < review.stars;
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 18,
                    color: isFilled
                        ? AppColors.matchMedium
                        : AppColors.slate300,
                  ),
                );
              }),
              if (review.propertyTitle != null &&
                  review.propertyTitle!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.skyFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      review.propertyTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandSky,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Review comment
          if (review.comment != null && review.comment!.isNotEmpty)
            Text(
              '"${review.comment}"',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: textColor.withValues(alpha: 0.88),
                height: 1.4,
              ),
            )
          else
            const Text(
              'No written review',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.slate500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.warningFill,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 38,
                color: AppColors.matchMedium,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Reviews from tenants will appear here after they book and rate their stay.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
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

class _ReviewItem {
  const _ReviewItem({
    required this.name,
    required this.date,
    required this.stars,
    this.comment,
    this.propertyTitle,
  });

  final String name;
  final String date;
  final int stars;
  final String? comment;
  final String? propertyTitle;
}
