import '../widgets/collapsible_detail_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/firestore/property_ratings_aggregator.dart';
import '../../inquiry/widgets/invite_button.dart';
import '../../owner/model/compatible_tenant.dart';
import '../../owner_onboarding/widgets/listing_form_widgets.dart';

// Compiled once instead of on every call.
final RegExp _kWhitespaceRe = RegExp(r'\s+');

/// One review given by an owner/landlord to this tenant.
class _TenantReviewItem {
  const _TenantReviewItem({
    required this.raterName,
    required this.stars,
    required this.date,
    this.comment,
    this.propertyTitle,
    this.raterInitials = 'L',
  });

  final String raterName;
  final int stars;
  final String date;
  final String? comment;
  final String? propertyTitle;
  final String raterInitials;
}

/// Detail view for a compatible tenant (owner perspective).
/// Displays personal information, contact details, and living preferences.
///
/// Follows the profile card and gradient styling from the profile screen.
class TenantDetailScreen extends StatefulWidget {
  const TenantDetailScreen({
    required this.tenant,
    this.user,
    this.profile,
    this.phone,
    this.showInviteButton = false,
    this.propertyId,
    super.key,
  });

  /// Property Find Tenants is scoped to; limits the invite to it.
  final String? propertyId;

  final CompatibleTenant tenant;
  final UserDoc? user;
  final TenantProfileDoc? profile;
  final String? phone;
  final bool showInviteButton;

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  UserDoc? _user;
  TenantProfileDoc? _profile;

  bool _isLoadingReviews = true;
  List<_TenantReviewItem> _reviews = const [];
  // Pagination of the written-review list (newest first, one page at a time).
  DocumentSnapshot<Object?>? _lastDoc;
  bool _hasMore = false;
  bool _loadingMore = false;
  // Rater names / listing titles already fetched, so a later page only reads
  // the ones it has not seen yet.
  final Map<String, String> _raterNames = {};
  final Map<String, String> _propertyTitles = {};

  /// Header / summary: the tenant's stored counters on tenantProfiles/{uid}
  /// (avg derived), never a count of the loaded review pages.
  OwnerRatingSummary get _rating =>
      OwnerRatingSummary.fromTenantProfile(_profile);
  double get _avgRating => _rating.average;
  int get _totalReviews => _rating.totalRatings;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _profile = widget.profile;
    if (_profile == null || _user == null) {
      _loadData();
    }
    _loadReviews();
  }

  // Load the next page when the screen is scrolled near its end (the reviews
  // card is the last section).
  bool _onScroll(ScrollNotification n) {
    if (_hasMore &&
        !_loadingMore &&
        n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
      _loadReviews(more: true);
    }
    return false;
  }

  Future<void> _loadReviews({bool more = false}) async {
    if (more && (_loadingMore || !_hasMore)) return;
    _loadingMore = more;
    try {
      final firestore = FirebaseFirestore.instance;
      final entries = await PropertyRatingsAggregator.fetchRatingDocsForTenant(
        firestore: firestore,
        tenantId: widget.tenant.tenantId,
        startAfter: more ? _lastDoc : null,
      );
      _hasMore = entries.length >= PropertyRatingsAggregator.reviewsPageSize;
      if (entries.isNotEmpty) _lastDoc = entries.last.doc;

      if (entries.isNotEmpty) {
        final raterIds = entries
            .map((e) => e.doc.data()['raterId'] as String?)
            .whereType<String>()
            .where((id) => id.isNotEmpty && !_raterNames.containsKey(id))
            .toSet();

        final userDocs = await Future.wait(
          raterIds.map((id) =>
              firestore.collection(FirestoreCollections.users).doc(id).get()),
        );

        for (final doc in userDocs) {
          if (doc.exists) {
            final d = doc.data() ?? {};
            final name =
                '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim();
            _raterNames[doc.id] = name.isNotEmpty ? name : 'Property Owner';
          }
        }

        for (final e in entries) {
          final id = (e.doc.data()['propertyId'] as String?)?.trim() ?? '';
          final title = e.propertyTitle;
          if (id.isNotEmpty && title != null) _propertyTitles[id] = title;
        }
        final propIds = entries
            .map((e) => (e.doc.data()['propertyId'] as String?)?.trim())
            .whereType<String>()
            .where((id) => id.isNotEmpty && !_propertyTitles.containsKey(id))
            .toSet();

        final propDocs = await Future.wait(
          propIds.map((id) => firestore
              .collection(FirestoreCollections.properties)
              .doc(id)
              .get()),
        );

        for (final doc in propDocs) {
          if (doc.exists) {
            final d = doc.data() ?? {};
            _propertyTitles[doc.id] = (d['title'] as String?) ?? 'Listing';
          }
        }

        final loaded = <_TenantReviewItem>[];

        for (final entry in entries) {
          final rating = RatingDoc.fromSnapshot(entry.doc);

          final rName = _raterNames[rating.raterId] ?? 'Property Owner';
          final parts = rName.split(_kWhitespaceRe).where((p) => p.isNotEmpty);
          final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();

          String dateStr = 'Recent';
          final at = rating.createdAt?.toDate();
          if (at != null) {
            const months = [
              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
            ];
            dateStr = '${months[at.month - 1]} ${at.day}, ${at.year}';
          }

          loaded.add(
            _TenantReviewItem(
              raterName: rName,
              stars: rating.stars.toInt(),
              date: dateStr,
              comment: rating.review?.trim(),
              propertyTitle: rating.propertyId != null
                  ? _propertyTitles[rating.propertyId!.trim()]
                  : null,
              raterInitials: initials.isNotEmpty ? initials : 'O',
            ),
          );
        }

        if (mounted) {
          setState(() {
            _reviews = more ? [..._reviews, ...loaded] : loaded;
            _isLoadingReviews = false;
          });
        }
        _loadingMore = false;
        return;
      }
    } catch (e) {
      debugPrint('Error loading tenant ratings: $e');
    }

    _loadingMore = false;
    if (more) return; // keep what is already shown
    if (mounted) {
      setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _loadData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final futures = <Future<void>>[];
      if (_profile == null) {
        futures.add(
          firestore
              .collection(FirestoreCollections.tenantProfiles)
              .doc(widget.tenant.tenantId)
              .get()
              .then((snap) {
            if (snap.exists && mounted) {
              setState(() {
                // Also carries the rating counters shown in the header.
                _profile = TenantProfileDoc.fromSnapshot(snap);
              });
            }
          }),
        );
      }
      if (_user == null) {
        futures.add(
          firestore
              .collection(FirestoreCollections.users)
              .doc(widget.tenant.tenantId)
              .get()
              .then((snap) {
            if (snap.exists && mounted) {
              setState(() {
                _user = UserDoc.fromSnapshot(snap);
              });
            }
          }),
        );
      }
      await Future.wait(futures);
    } catch (_) {
      // Best-effort load; fallback to fields on CompatibleTenant
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Flexible';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tenant = widget.tenant;
    final user = _user;
    final profile = _profile;

    final photoUrl = user?.profilePhoto;
    final phoneText = (widget.phone != null && widget.phone!.trim().isNotEmpty)
        ? widget.phone!.trim()
        : (user?.phone.isNotEmpty == true ? user!.phone : 'Shared in inquiry');
    final emailText = user?.email.isNotEmpty == true ? user!.email : '—';

    final genderText = tenant.gender.isNotEmpty
        ? tenant.gender
        : (user?.gender.isNotEmpty == true ? user!.gender : '—');
    final occupationText = profile?.occupation ?? tenant.occupation ?? '—';
    final schoolText = profile?.school ?? tenant.school ?? '—';
    final groupSizeText = '${profile?.groupSize ?? 1} person(s)';

    final budgetText = '₱${profile?.maxBudget ?? tenant.maxBudget}/month';
    final moveInText = _formatDate(profile?.moveInDate?.toDate());
    final roomTypeText = profile?.roomType?.isNotEmpty == true
        ? profile!.roomType!
        : 'Any room type';
    final smokingText = (profile?.isSmoker ?? false) ? 'Smoker' : 'Non-smoker';
    final petText = (profile?.hasPet ?? false) ? 'Has pet' : 'No pets';
    final wifiText = (profile?.needsWifi ?? false)
        ? 'Wi-Fi required'
        : 'Not required';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // ── Top Decorative Sky-Blue Gradient Backdrop ────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.1,
                    colors: [
                      AppColors.sky200.withValues(alpha: 0.70),
                      AppColors.skyFill.withValues(alpha: 0.35),
                      AppColors.surface.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.45, 0.88],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Bar ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.slate900.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: AppColors.slate900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Tenant Profile',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Content ──────────────────────────────────────────────────
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Profile Card (Matching ProfileScreen design) ────
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.surface, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.slate900.withValues(alpha: 0.04),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                // Avatar with gradient ring
                                Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.sky300, // Light blue
                                        AppColors.brandSky, // Blue
                                        AppColors.emerald500, // Emerald
                                      ],
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.surface,
                                    ),
                                    child: CircleAvatar(
                                      radius: 32,
                                      backgroundColor: AppColors.skyFill,
                                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                          ? ResizeImage.resizeIfNeeded(340, null, NetworkImage(photoUrl))
                                          : null,
                                      child: (photoUrl == null || photoUrl.isEmpty)
                                          ? Text(
                                              tenant.initials,
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.brandSky,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tenant.name,
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.slate900,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 3.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.emerald50,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppColors.emerald500,
                                                width: 0.8,
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle_rounded,
                                                  size: 13,
                                                  color: AppColors.emerald500,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Compatible Match',
                                                  style: TextStyle(
                                                    fontFamily: 'DM Sans',
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.emerald600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (_totalReviews > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 9,
                                                vertical: 3.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.warningFill,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: AppColors.matchMedium,
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.star_rounded,
                                                    size: 14,
                                                    color: AppColors.amber600,
                                                  ),
                                                  const SizedBox(width: 3.5),
                                                  Text(
                                                    '${_avgRating.toStringAsFixed(1)} ($_totalReviews)',
                                                    style: const TextStyle(
                                                      fontFamily: 'DM Sans',
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.amber700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else if (!_isLoadingReviews)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 9,
                                                vertical: 3.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.warningFill,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: AppColors.amberBorder200,
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.star_rounded,
                                                    size: 13,
                                                    color: AppColors.matchMedium,
                                                  ),
                                                  SizedBox(width: 3.5),
                                                  Text(
                                                    'No ratings yet',
                                                    style: TextStyle(
                                                      fontFamily: 'DM Sans',
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.amber700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Passes property rules and requirements',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 11.5,
                                          color: AppColors.slate500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Section 1: Contact Information ──────────────────
                        CollapsibleDetailCard(
                          icon: Icons.contact_phone_outlined,
                          title: 'Contact details',
                          child: Column(
                            children: [
                              _detailRow(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: phoneText,
                              ),
                              _divider(),
                              _detailRow(
                                icon: Icons.mail_outline_rounded,
                                label: 'Email',
                                value: emailText,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Section 2: Personal Profile ─────────────────────
                        CollapsibleDetailCard(
                          icon: Icons.person_outline_rounded,
                          title: 'Personal details',
                          child: Column(
                            children: [
                              _detailRow(label: 'Gender', value: genderText),
                              _divider(),
                              _detailRow(label: 'Occupation', value: occupationText),
                              _divider(),
                              _detailRow(label: 'School / Workplace', value: schoolText),
                              _divider(),
                              _detailRow(label: 'Group size', value: groupSizeText, isLast: true),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Section 3: Living & Rental Preferences ───────────
                        CollapsibleDetailCard(
                          icon: Icons.tune_rounded,
                          title: 'Rental & living preferences',
                          child: Column(
                            children: [
                              _detailRow(label: 'Maximum budget', value: budgetText),
                              _divider(),
                              _detailRow(label: 'Target move-in', value: moveInText),
                              _divider(),
                              _detailRow(label: 'Room preference', value: roomTypeText),
                              _divider(),
                              _detailRow(label: 'Smoking policy', value: smokingText),
                              _divider(),
                              _detailRow(label: 'Pet policy', value: petText),
                              _divider(),
                              _detailRow(label: 'Internet', value: wifiText),
                              if (profile?.preferredAmenities?.isNotEmpty ?? false) ...[
                                _divider(),
                                _amenitiesRow(
                                  label: 'Preferred amenities',
                                  amenities: profile!.preferredAmenities!,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Section 4: Landlord Ratings & Reviews (at the bottom) ───
                        _buildRatingsSection(),

                        // ── Optional Invite Button (only if showInviteButton is true) ──
                        if (widget.showInviteButton) ...[
                          const SizedBox(height: 24),
                          InviteButton(
                            tenantId: tenant.tenantId,
                            tenantName: tenant.name,
                            bScore: tenant.bScore,
                            propertyId: widget.propertyId,
                          ),
                        ],
                      ],
                    ),
                  ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required String label,
    required String value,
    IconData? icon,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.slate500),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.slate500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amenitiesRow({
    required String label,
    required List<String> amenities,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final amenity in amenities)
                _TenantAmenityChip(label: amenity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    Widget? badge;
    if (_totalReviews > 0) {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.warningFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 14, color: AppColors.matchMedium),
            const SizedBox(width: 3),
            Text(
              '${_avgRating.toStringAsFixed(1)} ($_totalReviews)',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.amber700,
              ),
            ),
          ],
        ),
      );
    } else if (!_isLoadingReviews) {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.warningFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 13, color: AppColors.matchMedium),
            SizedBox(width: 3),
            Text(
              'No ratings yet',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.amber700,
              ),
            ),
          ],
        ),
      );
    }

    return CollapsibleDetailCard(
      icon: Icons.star_rounded,
      iconColor: AppColors.matchMedium,
      title: 'Landlord ratings & reviews',
      badgeWidget: badge,
      child: _isLoadingReviews
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.brandSky,
                  ),
                ),
              ),
            )
          : (_reviews.isEmpty && _totalReviews == 0)
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.warningFill,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 26,
                          color: AppColors.matchMedium,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No landlord reviews yet',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'This tenant has not received ratings or feedback from previous landlords yet. Once a stay is completed, feedback will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: AppColors.slate500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 22,
                                  color: AppColors.matchMedium,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _avgRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.amber700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    final isFilled = index < _avgRating.round();
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Icon(
                                        isFilled
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        size: 16,
                                        color: isFilled
                                            ? AppColors.matchMedium
                                            : AppColors.slate300,
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Based on $_totalReviews landlord review${_totalReviews == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_reviews.isNotEmpty) ...[
                      const Divider(height: 1, color: AppColors.fieldFill),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: _reviews.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: AppColors.fieldFill),
                        itemBuilder: (ctx, i) {
                          final review = _reviews[i];
                          return Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.skyFill,
                                      child: Text(
                                        review.raterInitials,
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brandSky,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            review.raterName,
                                            style: const TextStyle(
                                              fontFamily: 'DM Sans',
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.slate900,
                                            ),
                                          ),
                                          if (review.propertyTitle != null) ...[
                                            const SizedBox(height: 1),
                                            Text(
                                              'Stayed at ${review.propertyTitle!}',
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.slate500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Text(
                                      review.date,
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 11.5,
                                        color: AppColors.slate400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(5, (sIndex) {
                                    final isFilled = sIndex < review.stars;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Icon(
                                        isFilled
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        size: 15,
                                        color: isFilled
                                            ? AppColors.matchMedium
                                            : AppColors.slate300,
                                      ),
                                    );
                                  }),
                                ),
                                if (review.comment != null &&
                                    review.comment!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.slate50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.slate200,
                                        width: 0.6,
                                      ),
                                    ),
                                    child: Text(
                                      review.comment!,
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 12.5,
                                        height: 1.4,
                                        color: AppColors.slate700,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Rated without written comment',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11.5,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.slate400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: AppColors.fieldFill);
}

class _TenantAmenityChip extends StatelessWidget {
  const _TenantAmenityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final iconData = amenityIconFor(label);

    return Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 11, 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.55),
          width: 0.75,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              iconData,
              size: 13,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.slate900,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
