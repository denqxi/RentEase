import '../widgets/collapsible_detail_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_links.dart';
import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/firestore/property_ratings_aggregator.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/url_opener.dart';
import '../../owner_onboarding/data/repositories/owner_onboarding_repository_impl.dart';
import '../../owner_onboarding/domain/entities/owner_credentials.dart';

// Compiled once instead of on every call.
final RegExp _kWhitespaceRe = RegExp(r'\s+');

/// Detail view for a property owner / landlord (tenant perspective).
/// Displays host information, contact details, and listing overview.
class OwnerDetailScreen extends StatefulWidget {
  const OwnerDetailScreen({
    this.ownerId,
    this.owner,
    this.ownerProfile,
    this.property,
    required this.fallbackName,
    this.phone,
    this.isVerified = false,
    super.key,
  });

  final String? ownerId;
  final UserDoc? owner;
  final OwnerProfileDoc? ownerProfile;
  final PropertyDoc? property;
  final String fallbackName;
  final String? phone;
  final bool isVerified;

  @override
  State<OwnerDetailScreen> createState() => _OwnerDetailScreenState();
}

class _OwnerDetailScreenState extends State<OwnerDetailScreen> {
  UserDoc? _owner;
  OwnerProfileDoc? _ownerProfile;
  bool _isVerified = false;
  bool _isLoadingReviews = true;
  List<_OwnerReviewItem> _reviews = const [];
  double _avgRating = 0.0;
  int _totalReviews = 0;
  OwnerCredentials _credentials = const OwnerCredentials();
  bool _credentialsLoaded = false;

  @override
  void initState() {
    super.initState();
    _owner = widget.owner;
    _ownerProfile = widget.ownerProfile;
    _isVerified =
        widget.isVerified || (_ownerProfile?.verificationStatus == 'verified');
    if (_owner == null || _ownerProfile == null) {
      _loadOwnerData();
    }
    _loadReviews();
    _loadCredentials();
  }

  /// Business permit and ownership document (never the ID). firestore.rules
  /// allow the reads only for a verified owner who turned on "Show
  /// credentials"; otherwise both come back empty.
  Future<void> _loadCredentials() async {
    final uid =
        widget.ownerId ?? widget.owner?.userId ?? widget.property?.ownerId;
    try {
      if (uid != null && uid.isNotEmpty) {
        final credentials = await OwnerOnboardingRepositoryImpl()
            .fetchCredentials(uid);
        if (mounted) setState(() => _credentials = credentials);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _credentialsLoaded = true);
    }
  }

  void _openDocument(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        backgroundColor: context.appColors.surface,
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 4,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Could not load this document.',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dtiLink() => TextButton.icon(
    // Opens in an in-app browser tab.
    onPressed: () => const UrlLauncherOpener().open(
      Uri.parse(AppLinks.dtiNegosyoKonekSearch),
    ),
    style: TextButton.styleFrom(
      padding: EdgeInsets.zero,
      foregroundColor: AppColors.primary,
    ),
    icon: const Icon(Icons.open_in_new_rounded, size: 16),
    label: const Text(
      'Search on DTI Business Name Search',
      style: TextStyle(fontSize: 14),
    ),
  );

  /// Tappable thumbnail for a shared document (zooms on tap).
  Widget _documentTile(String label, String url) => Expanded(
    child: GestureDetector(
      onTap: () => _openDocument(url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.appColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.appColors.fieldBorder,
                width: 0.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              cacheWidth: 600,
              errorBuilder: (_, _, _) => Center(
                child: Icon(
                  Icons.description_outlined,
                  color: context.appColors.hint,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );

  /// "Check the business": the documents the owner shares (business permit,
  /// ownership document) when they turned on "Show credentials", plus the
  /// DTI lookup either way.
  Widget _buildCheckBusinessCard() {
    final permit = _credentials.businessPermitUrl;
    final ownership = _credentials.ownershipDocumentUrl;
    final shared = !_credentials.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 18,
                color: context.appColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Check the business',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
          if (shared) ...[
            const SizedBox(height: 6),
            Text(
              'Documents shared by $_displayName and reviewed by RentEase. '
              'Tap to zoom.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: context.appColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (permit != null) _documentTile('Business permit', permit),
                if (permit != null && ownership != null)
                  const SizedBox(width: 10),
                if (ownership != null)
                  _documentTile('Ownership document', ownership),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            shared
                ? 'You can also search the business name on DTI\'s public list '
                      'of registered businesses.'
                : 'DTI keeps a public list of registered business names. Search '
                      'the property\'s name to see if it is registered.',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: context.appColors.textSecondary,
              height: 1.35,
            ),
          ),
          _dtiLink(),
        ],
      ),
    );
  }

  Future<void> _loadOwnerData() async {
    final uid =
        widget.ownerId ?? widget.owner?.userId ?? widget.property?.ownerId;
    if (uid == null || uid.isEmpty) return;

    try {
      final futures = <Future<void>>[];
      if (_owner == null) {
        futures.add(
          FirebaseFirestore.instance
              .collection(FirestoreCollections.users)
              .doc(uid)
              .get()
              .then((snap) {
                if (snap.exists && mounted) {
                  setState(() {
                    _owner = UserDoc.fromSnapshot(snap);
                  });
                }
              }),
        );
      }
      if (_ownerProfile == null) {
        futures.add(
          FirebaseFirestore.instance
              .collection(FirestoreCollections.ownerProfiles)
              .doc(uid)
              .get()
              .then((snap) {
                if (snap.exists && mounted) {
                  setState(() {
                    _ownerProfile = OwnerProfileDoc.fromSnapshot(snap);
                    if (_ownerProfile?.verificationStatus == 'verified') {
                      _isVerified = true;
                    }
                  });
                }
              }),
        );
      }
      await Future.wait(futures);
    } catch (_) {}
  }

  Future<void> _loadReviews() async {
    final uid =
        widget.ownerId ?? widget.owner?.userId ?? widget.property?.ownerId;
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _isLoadingReviews = false);
      return;
    }
    try {
      // Host rating = roll-up of the owner's properties' counters (one small
      // `properties where ownerId == uid` query; the owner has no counter of
      // their own). The list shows only the 10 most recent written reviews.
      final summary = await PropertyRatingsAggregator.getOwnerRollupRating(
        firestore: FirebaseFirestore.instance,
        ownerId: uid,
      );
      final ownerEntries =
          await PropertyRatingsAggregator.fetchRatingDocsForOwner(
            firestore: FirebaseFirestore.instance,
            ownerId: uid,
            limit: 10,
          );

      if (!mounted) return;

      final ratersToFetch = <String>{};
      for (final entry in ownerEntries) {
        final raterId = entry.doc.data()['raterId'] as String?;
        if (raterId != null && raterId.isNotEmpty) {
          ratersToFetch.add(raterId);
        }
      }

      final ratersMap = <String, String>{};
      if (ratersToFetch.isNotEmpty) {
        try {
          final usersSnap = await FirebaseFirestore.instance
              .collection(FirestoreCollections.users)
              .where(
                FieldPath.documentId,
                whereIn: ratersToFetch.take(10).toList(),
              )
              .get();
          for (final u in usersSnap.docs) {
            final data = u.data();
            final fn = (data['firstName'] as String?)?.trim() ?? '';
            final ln = (data['lastName'] as String?)?.trim() ?? '';
            final full = '$fn $ln'.trim();
            ratersMap[u.id] = full.isNotEmpty ? full : 'Tenant';
          }
        } catch (_) {}
      }

      final loaded = <_OwnerReviewItem>[];
      for (final entry in ownerEntries) {
        final rating = RatingDoc.fromSnapshot(entry.doc);
        final rName = ratersMap[rating.raterId] ?? 'Tenant';
        final dt = rating.createdAt?.toDate();
        final dateStr = dt != null ? _formatMemberSince(dt) : 'Recent';
        loaded.add(
          _OwnerReviewItem(
            raterName: rName,
            stars: rating.stars.toInt(),
            date: dateStr,
            comment: rating.review?.trim(),
            propertyTitle: entry.propertyTitle,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _reviews = loaded;
          _totalReviews = summary.totalRatings;
          _avgRating = summary.average;
          _isLoadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  String get _displayName {
    final o = _owner;
    if (o == null) return widget.fallbackName;
    final name = '${o.firstName} ${o.lastName}'.trim();
    return name.isNotEmpty ? name : widget.fallbackName;
  }

  String get _initials {
    final parts = _displayName
        .trim()
        .split(_kWhitespaceRe)
        .where((p) => p.isNotEmpty);
    final inits = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return inits.isEmpty ? '?' : inits;
  }

  String _formatMemberSince(DateTime? dt) {
    if (dt == null) return 'RentEase';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _owner?.profilePhoto;
    final phoneText = (widget.phone != null && widget.phone!.trim().isNotEmpty)
        ? widget.phone!.trim()
        : (_owner?.phone.isNotEmpty == true ? _owner!.phone : 'Shared in chat');
    final emailText = _owner?.email.isNotEmpty == true ? _owner!.email : '—';
    final p = widget.property;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: Stack(
        children: [
          // ── Top Decorative Sky-Blue Gradient Backdrop ────────────────────
          if (Theme.of(context).brightness == Brightness.light)
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
                        context.appColors.surface.withValues(alpha: 0.0),
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
                // ── Top Header Bar ───────────────────────────────────────────
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
                            color: context.appColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.slate900.withValues(
                                  alpha: 0.06,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Owner Profile',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.appColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Content ──────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Profile Card (Matching ProfileScreen design) ────
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: context.appColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: context.appColors.surface,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.slate900.withValues(
                                  alpha: 0.04,
                                ),
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
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.appColors.surface,
                                    ),
                                    child: CircleAvatar(
                                      radius: 32,
                                      backgroundColor: AppColors.skyFill,
                                      backgroundImage:
                                          (photoUrl != null &&
                                              photoUrl.isNotEmpty)
                                          ? ResizeImage.resizeIfNeeded(
                                              340,
                                              null,
                                              NetworkImage(photoUrl),
                                            )
                                          : null,
                                      child:
                                          (photoUrl == null || photoUrl.isEmpty)
                                          ? Text(
                                              _initials,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _displayName,
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: context.appColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isVerified
                                              ? AppColors.indigo50
                                              : context.appColors.fieldFill,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: _isVerified
                                                ? AppColors.sky400
                                                : context.appColors.hint,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _isVerified
                                                  ? Icons.verified_rounded
                                                  : Icons.shield_outlined,
                                              size: 13,
                                              color: _isVerified
                                                  ? AppColors.sky600
                                                  : context
                                                        .appColors
                                                        .textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _isVerified
                                                  ? 'Verified Owner'
                                                  : 'Property Host',
                                              style: TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: _isVerified
                                                    ? AppColors.sky700
                                                    : context
                                                          .appColors
                                                          .textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _isVerified
                                            ? 'Verified boarding house host on RentEase'
                                            : 'Registered property host on RentEase',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 11.5,
                                          color:
                                              context.appColors.textSecondary,
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

                        // ── Section 2: Host Details ─────────────────────────
                        CollapsibleDetailCard(
                          icon: Icons.badge_outlined,
                          title: 'Host details',
                          child: Column(
                            children: [
                              _detailRow(
                                label: 'Verification',
                                value: _isVerified
                                    ? 'Identity Verified'
                                    : 'Registered Host',
                              ),
                              _divider(),
                              _detailRow(
                                label: 'Role',
                                value: 'Property Landlord / Host',
                              ),
                              _divider(),
                              _detailRow(
                                label: 'Member since',
                                value: _formatMemberSince(
                                  _owner?.createdAt?.toDate(),
                                ),
                              ),
                              if ((_ownerProfile?.propertyCount ?? 0) > 0) ...[
                                _divider(),
                                _detailRow(
                                  label: 'Properties listed',
                                  value:
                                      '${_ownerProfile!.propertyCount} ${_ownerProfile!.propertyCount == 1 ? 'property' : 'properties'}',
                                ),
                              ],
                              // Roll-up of the owner's properties' counters
                              // (ownerProfiles has no live rating counter).
                              if (_totalReviews > 0) ...[
                                _divider(),
                                _detailRow(
                                  label: 'Host rating',
                                  value: () {
                                    final c = _totalReviews;
                                    final a = _avgRating;
                                    return '★ ${a.toStringAsFixed(1)} ($c ${c == 1 ? 'review' : 'reviews'})';
                                  }(),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Shared documents (if the owner allows) + DTI
                        // lookup. Waits for the load so the card doesn't
                        // change shape after it appears.
                        if (_credentialsLoaded) ...[
                          const SizedBox(height: 12),
                          _buildCheckBusinessCard(),
                        ],

                        if (p != null) ...[
                          const SizedBox(height: 12),
                          // ── Section 3: Property Inquired ──────────────────
                          CollapsibleDetailCard(
                            icon: Icons.home_work_outlined,
                            title: 'Listing information',
                            child: Column(
                              children: [
                                _detailRow(
                                  label: 'Property name',
                                  value: p.title,
                                ),
                                _divider(),
                                _detailRow(label: 'Location', value: p.address),
                                _divider(),
                                _detailRow(
                                  label: 'Monthly rent',
                                  value: '₱${p.monthlyRent}/mo',
                                ),
                                _divider(),
                                _detailRow(
                                  label: 'Deposit',
                                  value: '₱${p.depositAmount}',
                                ),
                                _divider(),
                                _detailRow(
                                  label: 'Advance',
                                  value: p.advanceMonths > 0
                                      ? '₱${(p.monthlyRent * p.advanceMonths).toInt()}'
                                      : 'None',
                                ),
                                _divider(),
                                _detailRow(
                                  label: 'Curfew',
                                  value: formatCurfew(p.curfewHours),
                                ),
                                _divider(),
                                _detailRow(
                                  label: 'Gender policy',
                                  value: p.allowedGender.isNotEmpty
                                      ? p.allowedGender
                                      : 'Mixed / Any',
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // ── Section 4: Host Ratings & Reviews (at the bottom) ───
                        _buildRatingsSection(),
                      ],
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
            Icon(icon, size: 16, color: context.appColors.textSecondary),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: context.appColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    Widget? badge;
    // Roll-up of the owner's properties' counters (see _loadReviews).
    final count = _totalReviews;
    final avg = _avgRating;

    if (count > 0) {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.warningFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: 14,
              color: AppColors.matchMedium,
            ),
            const SizedBox(width: 3),
            Text(
              '${avg.toStringAsFixed(1)} ($count)',
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
      title: 'Host ratings & reviews',
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
          : (_reviews.isEmpty && count == 0)
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
                  Text(
                    'No host reviews yet',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This landlord has not received feedback from tenants yet. Once a stay is completed, feedback will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: context.appColors.textSecondary,
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
                              avg.toStringAsFixed(1),
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
                                final isFilled = index < avg.round();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Icon(
                                    isFilled
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 16,
                                    color: isFilled
                                        ? AppColors.matchMedium
                                        : context.appColors.hint,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Total across host\'s properties ($count review${count == 1 ? '' : 's'})',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: context.appColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_reviews.isNotEmpty) ...[
                  Divider(height: 1, color: context.appColors.fieldFill),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _reviews.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: context.appColors.fieldFill),
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
                                  child: Text(
                                    review.raterName,
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: context.appColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  review.date,
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11.5,
                                    color: context.appColors.hint,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ...List.generate(5, (sIndex) {
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
                                          : context.appColors.hint,
                                    ),
                                  );
                                }),
                                if (review.propertyTitle != null &&
                                    review.propertyTitle!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
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
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.brandSky,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (review.comment != null &&
                                review.comment!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: context.appColors.fieldFill,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: context.appColors.fieldBorder,
                                    width: 0.6,
                                  ),
                                ),
                                child: Text(
                                  review.comment!,
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12.5,
                                    height: 1.4,
                                    color: context.appColors.textPrimary,
                                  ),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 4),
                              Text(
                                'Rated without written comment',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11.5,
                                  fontStyle: FontStyle.italic,
                                  color: context.appColors.hint,
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

  Widget _divider() => Divider(height: 1, color: context.appColors.fieldFill);
}

class _OwnerReviewItem {
  const _OwnerReviewItem({
    required this.raterName,
    required this.stars,
    required this.date,
    this.comment,
    this.propertyTitle,
  });

  final String raterName;
  final int stars;
  final String date;
  final String? comment;
  final String? propertyTitle;

  String get raterInitials {
    final parts = raterName
        .trim()
        .split(_kWhitespaceRe)
        .where((p) => p.isNotEmpty);
    final inits = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return inits.isEmpty ? '?' : inits;
  }
}
