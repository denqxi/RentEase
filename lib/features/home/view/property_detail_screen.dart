import 'dart:ui' show ImageFilter;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../core/firestore/property_ratings_aggregator.dart';
import '../../../core/firestore/tenant_profile_loader.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/guest_access_sheet.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../inquiry/view/start_inquiry.dart';
import '../../landlord_home/view/owner_detail_screen.dart';
import '../../matching/domain/entities/mismatch_reason.dart';
import '../../owner_onboarding/widgets/listing_form_widgets.dart'
    show amenityIconFor;
import '../../profile/view/edit_rental_preferences_screen.dart';
import '../cubit/home_cubit.dart';
import '../model/listing.dart';
import 'map_view_screen.dart';

// Compiled once instead of on every call.
final RegExp _kThousandsRe = RegExp(r'(\d)(?=(\d{3})+(?!\d))');

String _fmt(num value) => value
    .round()
    .toString()
    .replaceAllMapped(_kThousandsRe, (m) => '${m[1]},');
final RegExp _kWhitespaceRe = RegExp(r'\s+');

class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({
    this.propertyId,
    this.initialListing,
    this.initialPropertyDoc,
    this.property,
    this.isGuest = false,
    this.onPreferencesSaved,
    this.homeCubit,
    this.profile,
    this.inquiryId,
    this.initialTenantCi,
    super.key,
  });

  final String? propertyId;
  final Listing? initialListing;
  final PropertyDoc? initialPropertyDoc;
  final Map<String, dynamic>? property;
  final bool isGuest;
  final VoidCallback? onPreferencesSaved;
  final HomeCubit? homeCubit;
  final TenantProfileDoc? profile;
  final String? inquiryId;
  final double? initialTenantCi;

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late Map<String, dynamic> _property;
  bool _isLoadingDetails = false;
  TenantProfileDoc? _profile;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reviewsKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToReviews() {
    final ctx = _reviewsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _property = widget.property ?? _buildInitialPropertyMap();
    _loadAsyncDetailsIfNeeded();
    _loadProfileIfNeeded();
  }

  Future<void> _loadProfileIfNeeded() async {
    if (_profile != null || widget.isGuest) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final p = await loadOwnTenantProfile(FirebaseFirestore.instance, uid);
      if (mounted && p != null) {
        setState(() => _profile = p);
      }
    } catch (_) {}
  }

  Map<String, dynamic> _buildInitialPropertyMap() {
    final doc = widget.initialPropertyDoc;
    if (doc != null) {
      final double ci = widget.initialTenantCi ?? 0.0;
      return {
        'propertyId': doc.propertyId,
        'parentPropertyId': doc.parentPropertyId,
        'ownerId': doc.ownerId,
        'title': doc.title,
        'propertyName': doc.propertyName,
        'roomName': doc.roomName,
        'propertyType': doc.propertyType,
        'photoUrl': doc.photos.isNotEmpty ? doc.photos.first : null,
        'photos': List<String>.from(doc.photos),
        'address': doc.address,
        'monthlyRent': doc.monthlyRent,
        'distance': 0.0,
        'amenityScore': doc.amenityScore ?? doc.amenityList.length,
        'tenantCi': ci,
        'isVerified': doc.isVerified,
        'allowedGender': doc.allowedGender,
        'smokingAllowed': doc.smokingAllowed,
        'petsAllowed': doc.petsAllowed,
        'curfewHours': doc.curfewHours,
        'depositAmount': doc.depositAmount,
        'advanceMonths': doc.advanceMonths,
        'maxOccupants': doc.maxOccupants,
        'ownerName': 'Property Owner',
        'ownerInitials': 'PO',
        'memberSince': 'RentEase',
        'propertyCount': 1,
        'amenityList': doc.amenityList,
        'bScore': doc.isAvailable ? 1 : 0,
        'isOutsidePreference': false,
        'isNonMatch': false,
        'matchKnown': false,
        'vacancyStatus': doc.vacancyStatus,
        'isAvailable': doc.isAvailable,
        'latitude': doc.location.latitude,
        'longitude': doc.location.longitude,
        'avgRating': doc.avgRating,
        'totalRatings': doc.totalRatings,
        'propertyDoc': doc,
      };
    }

    final l = widget.initialListing;
    if (l != null) {
      return {
        'propertyId': l.id,
        'ownerId': '',
        'title': l.title,
        'propertyType': l.propertyType,
        'photoUrl': l.photoUrl,
        'photos': List<String>.from(l.photos),
        'address': l.location,
        'monthlyRent': l.pricePerMonth,
        'distance': 0.0,
        'amenityScore': l.amenityScore,
        'tenantCi': l.matchPercent / 100.0,
        'isVerified': false,
        'allowedGender': 'Any',
        'smokingAllowed': false,
        'petsAllowed': false,
        'curfewHours': null,
        'depositAmount': l.pricePerMonth,
        'advanceMonths': 1,
        'maxOccupants': 1,
        'ownerName': 'Property Owner',
        'ownerInitials': 'PO',
        'memberSince': 'RentEase',
        'propertyCount': 1,
        'amenityList': const <String>[],
        'bScore': 1,
        'isOutsidePreference': false,
        'isNonMatch': false,
        'matchKnown': false,
        'vacancyStatus': 'available',
        'isAvailable': true,
        'avgRating': l.rating,
        'totalRatings': l.reviewCount,
        'propertyDoc': l.propertyDoc,
      };
    }

    final id = widget.propertyId ?? '';
    return {
      'propertyId': id,
      'ownerId': '',
      'title': 'Property',
      'address': 'Address loading...',
      'monthlyRent': 0,
      'bScore': 1,
      'isOutsidePreference': false,
      'isNonMatch': false,
      'matchKnown': false,
      'isAvailable': true,
      'photos': const <String>[],
      'amenityList': const <String>[],
    };
  }

  Future<void> _loadAsyncDetailsIfNeeded() async {
    final cubit = widget.homeCubit;
    final propId = (_property['propertyId'] as String?) ?? widget.propertyId;
    if (propId == null || propId.isEmpty) return;

    setState(() => _isLoadingDetails = true);
    try {
      Map<String, dynamic>? detail;
      if (cubit != null) {
        detail = await cubit.loadPropertyDetail(propId);
      }

      detail ??= {};
      // The repository knows when this tenant is NOT a match for the
      // property; the availability-based fallback below must not undo that
      // (Send Inquiry has to stay absent when B_score = 0).
      // Guests have no match docs (guest map always carries bScore 0); their
      // Send Inquiry opens the sign-up sheet, so they are never a non-match.
      final repoSaysNonMatch = !widget.isGuest &&
          (detail['isNonMatch'] == true || detail['bScore'] == 0);
      // Only a repository answer makes the match status known; without one
      // (e.g. opened from a notification) Send Inquiry stays absent.
      final repoKnowsMatch = detail.containsKey('bScore');

      // Always fetch fresh property document from Firestore to ensure
      // up-to-date ratings (avgRating, totalRatings), availability, and rooms.
      PropertyDoc? pDoc;
      try {
        final snap = await FirebaseFirestore.instance
            .collection(FirestoreCollections.properties)
            .doc(propId)
            .get();
        if (snap.exists) {
          var fetchedDoc = PropertyDoc.fromSnapshot(snap);
          try {
            fetchedDoc = await PropertyRatingsAggregator.hydrateProperty(
              FirebaseFirestore.instance,
              fetchedDoc,
              forceRefresh: true,
            );
          } catch (_) {}
          pDoc = fetchedDoc;
          detail.addAll({
            'propertyId': propId,
            'parentPropertyId': pDoc.parentPropertyId,
            'ownerId': pDoc.ownerId,
            'title': pDoc.title,
            'propertyName': pDoc.propertyName,
            'roomName': pDoc.roomName,
            'propertyType': pDoc.propertyType ?? 'Boarding House',
            'photoUrl': pDoc.photos.isNotEmpty
                ? pDoc.photos.first
                : pDoc.propertyCoverPhoto,
            'photos': List<String>.from(pDoc.photos),
            'address': pDoc.address,
            'monthlyRent': pDoc.monthlyRent,
            'depositAmount': pDoc.depositAmount,
            'advanceMonths': pDoc.advanceMonths,
            'isVerified': pDoc.isVerified,
            'allowedGender': pDoc.allowedGender,
            'smokingAllowed': pDoc.smokingAllowed,
            'petsAllowed': pDoc.petsAllowed,
            'curfewHours': pDoc.curfewHours,
            'maxOccupants': pDoc.maxOccupants,
            'amenityList': pDoc.amenityList,
            'bScore': pDoc.isAvailable ? 1 : 0,
            'isAvailable': pDoc.isAvailable,
            'latitude': pDoc.location.latitude,
            'longitude': pDoc.location.longitude,
            'avgRating': pDoc.avgRating ?? 0.0,
            'totalRatings': pDoc.totalRatings ?? 0,
            'propertyDoc': pDoc,
          });
        }
      } catch (e) {
        debugPrint('Error fetching fresh property doc: $e');
      }

      pDoc ??= widget.initialPropertyDoc ??
          (_property['propertyDoc'] as PropertyDoc?);

      // If tenantCi is 0 or not populated, query the matches collection
      final currentCi = (_property['tenantCi'] as num?)?.toDouble() ?? 0.0;
      if (currentCi <= 0 && !widget.isGuest) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          try {
            final matchSnap = await FirebaseFirestore.instance
                .collection(FirestoreCollections.matches)
                .doc('${uid}_$propId')
                .get();
            if (matchSnap.exists) {
              final m = MatchDoc.fromSnapshot(matchSnap);
              if (m.tenantCi != null && m.tenantCi! > 0) {
                detail['tenantCi'] = m.tenantCi!.toDouble();
              }
            }
          } catch (e) {
            debugPrint('Error fetching MatchDoc: $e');
          }
        }
      }

      // Ensure Owner information is always fetched and populated
      final ownerId = (detail['ownerId'] as String?) ??
          (_property['ownerId'] as String?) ??
          pDoc?.ownerId;

      if (ownerId != null && ownerId.isNotEmpty) {
        try {
          final ownerSnap = await FirebaseFirestore.instance
              .collection(FirestoreCollections.users)
              .doc(ownerId)
              .get();
          if (ownerSnap.exists) {
            final u = UserDoc.fromSnapshot(ownerSnap);
            final name = '${u.firstName} ${u.lastName}'.trim();
            final parts = name.split(_kWhitespaceRe).where((p) => p.isNotEmpty);
            final inits = parts.take(2).map((p) => p[0].toUpperCase()).join();

            detail['owner'] = u;
            if (name.isNotEmpty) {
              detail['ownerName'] = name;
            }
            detail['ownerPhotoUrl'] = u.profilePhoto;
            detail['ownerInitials'] = inits.isNotEmpty ? inits : 'PO';
            if (u.phone.isNotEmpty) {
              detail['ownerPhone'] = u.phone;
            }
            if (u.createdAt != null) {
              final dt = u.createdAt!.toDate();
              const months = [
                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
              ];
              detail['memberSince'] = '${months[dt.month - 1]} ${dt.year}';
            }
          }
        } catch (e) {
          debugPrint('Error fetching owner user: $e');
        }

        try {
          final opSnap = await FirebaseFirestore.instance
              .collection(FirestoreCollections.ownerProfiles)
              .doc(ownerId)
              .get();
          if (opSnap.exists) {
            final op = OwnerProfileDoc.fromSnapshot(opSnap);
            detail['ownerProfile'] = op;
            detail['isVerified'] = op.verificationStatus == 'verified';
            detail['propertyCount'] = op.propertyCount ?? 1;
          }
        } catch (e) {
          debugPrint('Error fetching owner profile: $e');
        }
      }

      if (!mounted) return;
      if (detail.isNotEmpty) {
        setState(() {
          _property = mergePropertyDetail(
            current: _property,
            detail: detail!,
            repoSaysNonMatch: repoSaysNonMatch,
            repoKnowsMatch: repoKnowsMatch,
          );
          _isLoadingDetails = false;
        });
      } else {
        setState(() => _isLoadingDetails = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  PropertyDoc _resolvePropertyDoc() {
    final dynamic storedDoc = _property['propertyDoc'];
    if (storedDoc is PropertyDoc) return storedDoc;
    if (widget.initialPropertyDoc != null) return widget.initialPropertyDoc!;

    final lat = (_property['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (_property['longitude'] as num?)?.toDouble() ?? 0.0;
    final photosList = (_property['photos'] as List?)?.cast<String>() ??
        (_property['photoUrl'] != null ? [_property['photoUrl'] as String] : <String>[]);
    final amenities =
        (_property['amenityList'] as List?)?.cast<String>() ?? const <String>[];

    return PropertyDoc(
      propertyId: _property['propertyId'] as String? ?? widget.propertyId ?? '',
      parentPropertyId: _property['parentPropertyId'] as String?,
      ownerId: _property['ownerId'] as String? ?? '',
      title: _property['title'] as String? ?? '',
      propertyName: _property['propertyName'] as String?,
      roomName: _property['roomName'] as String?,
      propertyType: _property['propertyType'] as String?,
      address: _property['address'] as String? ?? '',
      location: GeoPoint(lat, lng),
      geoHash: '',
      photos: photosList,
      monthlyRent: (_property['monthlyRent'] as num?) ?? 0,
      depositAmount: (_property['depositAmount'] as num?) ?? 0,
      advanceMonths: (_property['advanceMonths'] as num?) ?? 0,
      isAvailable: _property['isAvailable'] != false,
      vacancyStatus: (_property['vacancyStatus'] as String?) ?? 'available',
      isVerified: _property['isVerified'] == true,
      allowedGender: (_property['allowedGender'] as String?) ?? 'Any',
      smokingAllowed: _property['smokingAllowed'] == true,
      petsAllowed: _property['petsAllowed'] == true,
      maxOccupants: (_property['maxOccupants'] as num?) ?? 1,
      curfewHours: _property['curfewHours'] as num?,
      hasWifi: amenities.contains('WiFi') || amenities.contains('Wifi'),
      amenityList: amenities,
      avgRating: (_property['avgRating'] as num?)?.toDouble(),
      totalRatings: (_property['totalRatings'] as num?)?.toInt(),
    );
  }

  Future<void> _editPreferences(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const EditRentalPreferencesScreen(),
      ),
    );
    if (saved == true) {
      widget.onPreferencesSaved?.call();
      if (_property['isNonMatch'] == true && context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _shareProperty() {
    final title = _property['propertyName'] ?? _property['title'] ?? 'RentEase Property';
    final address = _property['address'] ?? '';
    final rent = _property['monthlyRent'] ?? _property['price'] ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "$title" (₱$rent/mo, $address)'),
        backgroundColor: AppColors.slate900,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _guardGuestAction(BuildContext context, VoidCallback action) {
    if (widget.isGuest) {
      GuestAccessSheet.show(context);
      return;
    }
    action();
  }

  void _openMapView(PropertyDoc propertyDoc, String title) {
    final lat = propertyDoc.location.latitude;
    final lng = propertyDoc.location.longitude;

    final propertyMap = Map<String, dynamic>.from(_property);
    propertyMap['latitude'] = lat;
    propertyMap['longitude'] = lng;
    propertyMap['propertyId'] = propertyDoc.propertyId;

    final poiLatLng = _profile?.poiLatLng;
    final LatLng? tenantPoi = (poiLatLng != null &&
            poiLatLng.latitude != 0.0 &&
            poiLatLng.longitude != 0.0)
        ? LatLng(poiLatLng.latitude, poiLatLng.longitude)
        : null;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MapViewScreen(
          properties: [propertyMap],
          initialPropertyId: propertyDoc.propertyId,
          isGuest: widget.isGuest,
          homeCubit: widget.homeCubit,
          poi: tenantPoi,
          poiLabel: _profile?.poiLabel,
          poiType: _profile?.poiType,
          isSinglePropertyMode: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutside = _property['isOutsidePreference'] == true;
    final bool isNonMatch = _property['isNonMatch'] == true;
    final bool isFilterMatch = _property['isFilterMatch'] == true;
    final reasons =
        (_property['mismatchReasons'] as List?)?.cast<MismatchReason>() ??
        const <MismatchReason>[];
    final int bScore = (_property['bScore'] as num?)?.toInt() ?? 1;
    final bool canInquire =
        bScore == 1 && !isFilterMatch && _property['matchKnown'] != false;
    final propId = (_property['propertyId'] as String?) ?? '';
    final int seed = propId.hashCode % 5 + 1;
    final displayName = (_property['title'] as String?) ?? 'Property';
    final displayType = ((_property['propertyType'] as String?)?.trim().isNotEmpty ?? false)
        ? (_property['propertyType'] as String).trim()
        : 'Boarding House';
    final address = (_property['address'] as String?) ?? '';
    final propertyDoc = _resolvePropertyDoc();

    num parseRent(dynamic val) {
      if (val is num && val > 0) return val;
      if (val is String) {
        final parsed = num.tryParse(val.replaceAll(RegExp(r'[^\d.]'), ''));
        if (parsed != null && parsed > 0) return parsed;
      }
      return 0;
    }

    final num monthlyRent = parseRent(_property['monthlyRent']) > 0
        ? parseRent(_property['monthlyRent'])
        : (parseRent(_property['rent']) > 0
            ? parseRent(_property['rent'])
            : (parseRent(_property['price']) > 0
                ? parseRent(_property['price'])
                : (parseRent(_property['pricePerMonth']) > 0
                    ? parseRent(_property['pricePerMonth'])
                    : (parseRent(propertyDoc.monthlyRent) > 0
                        ? parseRent(propertyDoc.monthlyRent)
                        : (parseRent(widget.initialListing?.pricePerMonth) > 0
                            ? parseRent(widget.initialListing?.pricePerMonth)
                            : (parseRent(widget.initialPropertyDoc?.monthlyRent) > 0
                                ? parseRent(widget.initialPropertyDoc?.monthlyRent)
                                : 0))))));
    final depositAmount = (_property['depositAmount'] as num?) ?? 0;
    final advanceMonths = (_property['advanceMonths'] as num?) ?? 0;
    final maxOccupants = ((_property['maxOccupants'] as num?) ?? 1).round();
    final allowedGender = (_property['allowedGender'] as String?) ?? 'Any';
    final curfewHours = _property['curfewHours'] as num?;
    final smokingAllowed = _property['smokingAllowed'] == true;
    final petsAllowed = _property['petsAllowed'] == true;
    final amenities =
        (_property['amenityList'] as List?)?.cast<String>() ?? const <String>[];

    // Photos list
    final rawPhotos = _property['photos'];
    final List<String> photos = (rawPhotos is List && rawPhotos.isNotEmpty)
        ? [for (final p in rawPhotos) if (p is String && p.isNotEmpty) p]
        : ((_property['photoUrl'] as String?)?.isNotEmpty ?? false)
            ? [_property['photoUrl'] as String]
            : const <String>[];

    final int matchPercent = widget.initialListing?.matchPercent ??
        (((_property['tenantCi'] as num?)?.toDouble() ?? 0.0) * 100).round();
    final Color matchDotColor =
        matchPercent >= 80 ? AppColors.matchHigh : AppColors.matchMedium;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: Stack(
        children: [
          // Subtle top-right gradient on the background (matching HomeScreen & SearchScreen)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.15,
                    colors: <Color>[
                      AppColors.onboardingSky.withValues(alpha: 0.75),
                      AppColors.skyFill.withValues(alpha: 0.40),
                      AppColors.skyFill.withValues(alpha: 0.0),
                    ],
                    stops: const <double>[0.0, 0.45, 0.88],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Custom Header with Back Button, Title, and Action Buttons (Share & Heart)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.slate200.withValues(alpha: 0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.slate900.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: AppColors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.of(context).pop(),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: context.appColors.textPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Property Details',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.appColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      // Share Button
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.slate200.withValues(alpha: 0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.slate900.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: AppColors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _shareProperty,
                            child: const Icon(
                              Icons.share_outlined,
                              color: AppColors.slate700,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Heart Button
                      StreamBuilder<Set<String>>(
                        stream: widget.homeCubit?.state.savedIds != null
                            ? null
                            : null,
                        builder: (context, _) {
                          final isSaved = widget.homeCubit?.state.savedIds.contains(propId) ??
                              widget.initialListing?.isSaved ??
                              false;
                          return Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.slate200.withValues(alpha: 0.6),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.slate900.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: AppColors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _guardGuestAction(
                                  context,
                                  () => widget.homeCubit?.toggleSaved(propId),
                                ),
                                child: Icon(
                                  isSaved ? Icons.favorite : Icons.favorite_border,
                                  color: isSaved ? AppColors.destructive : AppColors.slate700,
                                  size: 19,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (_isLoadingDetails)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.primary,
                    backgroundColor: AppColors.transparent,
                  ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),

                    // View-only banner if listing fails preferences (rounded corners, matching card width)
                    if (isNonMatch) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amberFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.amberPrimary.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.amberPrimary,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Doesn't match your preferences (view only)",
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.amberText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Temporary filter match banner (bilateral check explanation)
                    if (isFilterMatch) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amberFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.amberPrimary.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.tune_rounded,
                              color: AppColors.amberPrimary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Matches your temporary search filter",
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.amberText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "This listing fits your search adjustments, but is outside your saved profile. Update your profile preferences to run bilateral matching and send an inquiry.",
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11.5,
                                      color: context.appColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Outside session filter banner (rounded corners, matching card width)
                    if (isOutside) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amberFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.amberPrimary.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.amberPrimary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Outside your session filter',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.amberText,
                                    ),
                                  ),
                                  Text(
                                    [
                                      if ((_property['distanceExcess'] ?? 0) > 0)
                                        'Distance is ${_property['distanceExcess']} km over limit',
                                      if ((_property['budgetExcess'] ?? 0) > 0)
                                        'Budget is ₱${_property['budgetExcess']} over limit',
                                      if ((_property['distanceExcess'] ?? 0) == 0 &&
                                          (_property['budgetExcess'] ?? 0) == 0)
                                        'Budget is within range',
                                    ].join(' · '),
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11.5,
                                      color: context.appColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── 1. Photo Carousel with Thumbnails ─────────────────
                    _PropertyPhotoGallerySection(
                      photos: photos,
                      seed: seed,
                      propertyId: propId,
                      cubit: widget.homeCubit,
                      onSavedToggle: () => _guardGuestAction(
                        context,
                        () => widget.homeCubit?.toggleSaved(propId),
                      ),
                      matchPercent: matchPercent,
                      tenantCi: (_property['tenantCi'] as num?)?.toDouble() ?? widget.initialListing?.effectiveCi,
                      matchDotColor: matchDotColor,
                      isGuest: widget.isGuest,
                      isNonMatch: isNonMatch,
                      isFilterMatch: isFilterMatch,
                    ),
                    const SizedBox(height: 14),

                    // ── 2. Main Overview Card (Clickable Location) ────────
                    _PropertyMainOverviewCard(
                      displayName: displayName,
                      displayType: displayType,
                      address: address,
                      monthlyRent: monthlyRent,
                      propertyDoc: propertyDoc,
                      avgRating: (_property['avgRating'] as num?)?.toDouble(),
                      totalRatings: (_property['totalRatings'] as num?)?.toInt(),
                      onAddressTap: () => _openMapView(propertyDoc, displayName),
                      onReviewsTap: _scrollToReviews,
                    ),
                    const SizedBox(height: 14),

                    // ── 3. Rental Information Unified Card ─────────────────
                    _RentalInformationCard(
                      monthlyRent: monthlyRent,
                      depositAmount: depositAmount,
                      advanceMonths: advanceMonths,
                      maxOccupants: maxOccupants,
                      curfewHours: curfewHours,
                      allowedGender: allowedGender,
                      smokingAllowed: smokingAllowed,
                      petsAllowed: petsAllowed,
                      amenities: amenities,
                    ),
                    const SizedBox(height: 14),

                    // ── 6. Host / Owner Information Card ───────────────────
                    _HostInformationCard(
                      property: _property,
                      propertyDoc: propertyDoc,
                    ),
                    const SizedBox(height: 14),

                    // ── 6.1 Property Reviews Card (Non-expandable, scrollable) ─
                    KeyedSubtree(
                      key: _reviewsKey,
                      child: _PropertyReviewsCard(
                        propertyId: propertyDoc.propertyId,
                        parentPropertyId: propertyDoc.parentPropertyId,
                        ownerId: propertyDoc.ownerId,
                        propertyName: propertyDoc.propertyName,
                        title: propertyDoc.title,
                        initialAvgRating: (propertyDoc.avgRating != null && propertyDoc.avgRating! > 0)
                            ? propertyDoc.avgRating!.toDouble()
                            : (_property['avgRating'] as num?)?.toDouble(),
                        initialTotalRatings: (propertyDoc.totalRatings != null && propertyDoc.totalRatings! > 0)
                            ? propertyDoc.totalRatings!.toInt()
                            : (_property['totalRatings'] as num?)?.toInt(),
                        inquiryId: widget.inquiryId,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── 7. Why it doesn't match (for non-matches) ──────────
                    if (isNonMatch) ...[
                      if (reasons.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.slate900.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: AppColors.amberPrimary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Why it doesn't match",
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              for (final r in reasons)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: AppColors.matchMedium,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          r.detailLabel,
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 13,
                                            color: AppColors.slate600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // In-flow update preferences button (white button, subtle outline, soft shadow)
                      Container(
                        width: double.infinity,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.slate200,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.scrim.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: AppColors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _editPreferences(context),
                            child: const Center(
                              child: Text(
                                'Update my preferences',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    SizedBox(height: ((canInquire && !isOutside && !isNonMatch) || isOutside || isFilterMatch) ? 80 : 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
  bottomNavigationBar: ((canInquire && !isOutside && !isNonMatch) || isOutside || isFilterMatch)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Temporary filter match: bilateral check button to update profile
                    if (isFilterMatch)
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: () => _guardGuestAction(
                            context,
                            () => _editPreferences(context),
                          ),
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text(
                            'Update Preferences to Inquire',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.surface,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.appColors.ink,
                            foregroundColor: AppColors.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    // Match inquiry button (absent for non-matches and filter matches)
                    if (canInquire && !isOutside && !isNonMatch)
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () => _guardGuestAction(
                            context,
                            () => startInquiry(
                              context,
                              propertyId: propId,
                              matchId: _property['matchId'] as String?,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.appColors.ink,
                            foregroundColor: AppColors.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.isGuest ? 'Sign in to inquire' : 'Send Inquiry',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                      ),

                    // Outside session filters buttons
                    if (isOutside) ...[
                      if (canInquire) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () => _guardGuestAction(
                              context,
                              () => startInquiry(
                                context,
                                propertyId: propId,
                                matchId: _property['matchId'] as String?,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.appColors.ink,
                              foregroundColor: AppColors.surface,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Send Inquiry Anyway',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: OutlinedButton(
                          onPressed: () => _guardGuestAction(
                            context,
                            () => _editPreferences(context),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.appColors.ink),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Edit My Saved Preferences',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.appColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : null,
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// FULL SCREEN SWIPEABLE IMAGE VIEWER (SWIPE UP/DOWN/SIDEWAYS TO DISMISS)
// ─────────────────────────────────────────────────────────────────────────────

class _FullScreenSwipeableImageViewer extends StatefulWidget {
  const _FullScreenSwipeableImageViewer({
    required this.photos,
    required this.initialIndex,
    required this.seed,
  });

  final List<String> photos;
  final int initialIndex;
  final int seed;

  @override
  State<_FullScreenSwipeableImageViewer> createState() =>
      _FullScreenSwipeableImageViewerState();
}

class _FullScreenSwipeableImageViewerState
    extends State<_FullScreenSwipeableImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformController =
      TransformationController();
  Offset _dragOffset = Offset.zero;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (_isZoomed) return;
    setState(() {
      _dragOffset += Offset(0, details.delta.dy);
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_isZoomed) return;
    final dy = _dragOffset.dy.abs();
    final vy = details.primaryVelocity?.abs() ?? 0;
    if (dy > 80 || vy > 400) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isZoomed || widget.photos.length > 1) return;
    setState(() {
      _dragOffset += Offset(details.delta.dx, 0);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_isZoomed || widget.photos.length > 1) return;
    final dx = _dragOffset.dx.abs();
    final vx = details.primaryVelocity?.abs() ?? 0;
    if (dx > 80 || vx > 400) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double dragDistance = _dragOffset.distance;
    final double dragRatio = (dragDistance / 300).clamp(0.0, 1.0);
    final double bgOpacity = (1.0 - dragRatio * 0.8).clamp(0.0, 1.0);
    final double contentScale = (1.0 - dragRatio * 0.2).clamp(0.75, 1.0);

    return Scaffold(
      backgroundColor: AppColors.scrim.withValues(alpha: 0.94 * bgOpacity),
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onVerticalDragUpdate: _handleVerticalDragUpdate,
              onVerticalDragEnd: _handleVerticalDragEnd,
              onHorizontalDragUpdate: widget.photos.length <= 1
                  ? _handleHorizontalDragUpdate
                  : null,
              onHorizontalDragEnd: widget.photos.length <= 1
                  ? _handleHorizontalDragEnd
                  : null,
              behavior: HitTestBehavior.translucent,
              child: Transform.translate(
                offset: _dragOffset,
                child: Transform.scale(
                  scale: contentScale,
                  child: Center(
                    child: widget.photos.length > 1
                        ? PageView.builder(
                            controller: _pageController,
                            physics: _isZoomed
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                            onPageChanged: (i) {
                              setState(() {
                                _currentIndex = i;
                                _transformController.value = Matrix4.identity();
                                _isZoomed = false;
                              });
                            },
                            itemCount: widget.photos.length,
                            itemBuilder: (ctx, index) {
                              return InteractiveViewer(
                                transformationController: _transformController,
                                minScale: 1.0,
                                maxScale: 4.0,
                                child: Image.network(
                                  widget.photos[index],
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) =>
                                      ListingImagePlaceholder(
                                    seed: widget.seed,
                                    photoUrl: null,
                                  ),
                                ),
                              );
                            },
                          )
                        : InteractiveViewer(
                            transformationController: _transformController,
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: Image.network(
                              widget.photos.first,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  ListingImagePlaceholder(
                                seed: widget.seed,
                                photoUrl: null,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _dragOffset == Offset.zero ? 1.0 : 0.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.scrim.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.surface,
                          size: 22,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    if (widget.photos.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.scrim.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.photos.length}',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// PHOTO CAROUSEL WITH THUMBNAILS (MATCHING PROPERTY MANAGER SCREEN)
// ─────────────────────────────────────────────────────────────────────────────

class _PropertyPhotoGallerySection extends StatefulWidget {
  const _PropertyPhotoGallerySection({
    required this.photos,
    required this.seed,
    this.propertyId,
    this.cubit,
    this.onSavedToggle,
    required this.matchPercent,
    this.tenantCi,
    required this.matchDotColor,
    required this.isGuest,
    required this.isNonMatch,
    this.isFilterMatch = false,
  });

  final List<String> photos;
  final int seed;
  final String? propertyId;
  final HomeCubit? cubit;
  final VoidCallback? onSavedToggle;
  final int matchPercent;
  final double? tenantCi;
  final Color matchDotColor;
  final bool isGuest;
  final bool isNonMatch;
  final bool isFilterMatch;

  @override
  State<_PropertyPhotoGallerySection> createState() =>
      _PropertyPhotoGallerySectionState();
}

class _PropertyPhotoGallerySectionState
    extends State<_PropertyPhotoGallerySection> {
  late final PageController _pageController;
  int _selectedPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullScreenViewer(int initialIndex) {
    if (widget.photos.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: AppColors.transparent,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _FullScreenSwipeableImageViewer(
              photos: widget.photos,
              initialIndex: initialIndex,
              seed: widget.seed,
            ),
          );
        },
      ),
    );
  }

  Widget _buildThumbnail(
    String photoUrl,
    int index,
    bool isSelected, {
    int? overlayCount,
  }) {
    return GestureDetector(
      onTap: () {
        if (overlayCount != null) {
          _openFullScreenViewer(index);
        } else {
          setState(() => _selectedPhotoIndex = index);
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryCyan : AppColors.slate200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                photoUrl,
                cacheWidth: 300,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.fieldFill,
                  child: const Icon(
                    Icons.broken_image,
                    size: 18,
                    color: AppColors.hint,
                  ),
                ),
              ),
              if (overlayCount != null)
                Container(
                  color: AppColors.scrim.withValues(alpha: 0.55),
                  alignment: Alignment.center,
                  child: Text(
                    '+$overlayCount',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.surface,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final photoCount = photos.length;
    final safeIndex = photoCount > 0
        ? _selectedPhotoIndex.clamp(0, photoCount - 1)
        : 0;

    final mainImageWidget = Container(
      height: 192,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.fieldFill,
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: photoCount > 0
                ? PageView.builder(
                    controller: _pageController,
                    itemCount: photoCount,
                    onPageChanged: (index) {
                      setState(() => _selectedPhotoIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final photoUrl = photos[index];
                      return GestureDetector(
                        onTap: () => _openFullScreenViewer(index),
                        child: Image.network(
                          photoUrl,
                          cacheWidth: 1280,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, _, _) =>
                              ListingImagePlaceholder(
                            seed: widget.seed,
                            photoUrl: null,
                          ),
                        ),
                      );
                    },
                  )
                : ListingImagePlaceholder(
                    seed: widget.seed,
                    photoUrl: null,
                  ),
          ),

          // Outline border overlay
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.slate200.withValues(alpha: 0.8),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),

          // Top-left: Match score / Mismatch badge (clean white pill with sparkle icon)
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
                  if (widget.isNonMatch) ...[
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 12,
                      color: AppColors.amber700,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Doesn't match",
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ] else if (widget.isFilterMatch) ...[
                    const Icon(
                      Icons.tune_rounded,
                      size: 12,
                      color: AppColors.amber700,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Filter Match',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ] else if (!widget.isGuest &&
                      widget.matchPercent > 0) ...[
                    const Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: AppColors.primaryCyan,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.matchPercent}% Match',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ] else if (!widget.isGuest) ...[
                    const Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: AppColors.primaryCyan,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (widget.tenantCi != null && widget.tenantCi! > 0)
                          ? '${(widget.tenantCi! * 100).round()}% Match'
                          : '0% Match',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: AppColors.slate600,
                    ),
                    const SizedBox(width: 4),
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

          // Bottom-left: Photo count badge (dark glass pill matching screenshot)
          if (photoCount > 0)
            Positioned(
              bottom: 10,
              left: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.scrim.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.surface.withValues(alpha: 0.35),
                        width: 0.6,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_outlined,
                          size: 12.5,
                          color: AppColors.surface,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          photoCount > 1
                              ? '${safeIndex + 1} / $photoCount'
                              : '$photoCount',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.surface,
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
    );

    if (photoCount <= 1) {
      return mainImageWidget;
    }

    return SizedBox(
      height: 192,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: mainImageWidget),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: photoCount == 2
                ? Column(
                    children: [
                      Expanded(
                        child: _buildThumbnail(
                          photos[0],
                          0,
                          safeIndex == 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: _buildThumbnail(
                          photos[1],
                          1,
                          safeIndex == 1,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        child: _buildThumbnail(
                          photos[0],
                          0,
                          safeIndex == 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: _buildThumbnail(
                          photos[1],
                          1,
                          safeIndex == 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: _buildThumbnail(
                          photos[2],
                          2,
                          safeIndex >= 2,
                          overlayCount:
                              photoCount > 3 ? photoCount - 3 : null,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN OVERVIEW (NAME, LOCATION, REVIEWS REDIRECT, RENT)
// ─────────────────────────────────────────────────────────────────────────────

class _PropertyMainOverviewCard extends StatefulWidget {
  const _PropertyMainOverviewCard({
    required this.displayName,
    required this.displayType,
    required this.address,
    required this.monthlyRent,
    required this.propertyDoc,
    this.avgRating,
    this.totalRatings,
    this.onAddressTap,
    this.onReviewsTap,
  });

  final String displayName;
  final String displayType;
  final String address;
  final num monthlyRent;
  final PropertyDoc propertyDoc;
  final double? avgRating;
  final int? totalRatings;
  final VoidCallback? onAddressTap;
  final VoidCallback? onReviewsTap;

  @override
  State<_PropertyMainOverviewCard> createState() =>
      _PropertyMainOverviewCardState();
}

class _PropertyMainOverviewCardState
    extends State<_PropertyMainOverviewCard> {
  bool _isAddressExpanded = false;

  @override
  Widget build(BuildContext context) {
    final displayName = widget.displayName;
    final displayType = widget.displayType;
    final address = widget.address;
    final monthlyRent = widget.monthlyRent;
    final onAddressTap = widget.onAddressTap;

    final double avg = (widget.avgRating != null && widget.avgRating! > 0)
        ? widget.avgRating!
        : ((widget.propertyDoc.avgRating != null &&
                widget.propertyDoc.avgRating! > 0)
            ? widget.propertyDoc.avgRating!.toDouble()
            : 0.0);
    final int count = (widget.totalRatings != null && widget.totalRatings! > 0)
        ? widget.totalRatings!
        :
        widget.propertyDoc.totalRatings?.toInt() ??
        0;
    final hasReviews = avg > 0 || count > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Top-left reviews (clickable) & Top-right price in one line (/ mo)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top-left: Yellow Star rating and reviews text (optically aligned with title below)
              Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: widget.onReviewsTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2, right: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: const Offset(-1, 0),
                          child: const Icon(
                            Icons.star_rounded,
                            size: 20,
                            color: AppColors.matchMedium, // Vibrant yellow star
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          hasReviews
                              ? '${avg.toStringAsFixed(1)} ($count ${count == 1 ? 'review' : 'reviews'})'
                              : 'No reviews yet',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight:
                                hasReviews ? FontWeight.w700 : FontWeight.w500,
                            color: hasReviews
                                ? context.appColors.textPrimary
                                : AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Top-right: Price on one line with / mo
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₱${_fmt(monthlyRent)}',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 21.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryCyan,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      '/ mo',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Title (same size as price, slightly bigger)
          Text(
            displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 21.5,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
              letterSpacing: -0.3,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),

          // Property type
          Text(
            displayType,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: 8),

          // Location row: Lighter smaller gray pin + Address + Circular map button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: AppColors.slate400,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _isAddressExpanded = !_isAddressExpanded;
                    });
                  },
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topLeft,
                    child: Text(
                      address,
                      maxLines: _isAddressExpanded ? null : 1,
                      overflow: _isAddressExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.slate600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
              if (onAddressTap != null) ...[
                const SizedBox(width: 8),
                Material(
                  color: AppColors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: onAddressTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.slate200.withValues(alpha: 0.8),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.map_outlined,
                        size: 15,
                        color: AppColors.primaryCyan,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // Separation line below address
          const Divider(
            height: 1,
            thickness: 0.8,
            color: AppColors.fieldFill,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNIFIED RENTAL INFORMATION CARD (RENT & CAPACITY, HOUSE RULES, AMENITIES)
// ─────────────────────────────────────────────────────────────────────────────

class _RentalInformationCard extends StatefulWidget {
  const _RentalInformationCard({
    required this.monthlyRent,
    required this.depositAmount,
    required this.advanceMonths,
    required this.maxOccupants,
    required this.curfewHours,
    required this.allowedGender,
    required this.smokingAllowed,
    required this.petsAllowed,
    required this.amenities,
  });

  final num monthlyRent;
  final num depositAmount;
  final num advanceMonths;
  final int maxOccupants;
  final num? curfewHours;
  final String allowedGender;
  final bool smokingAllowed;
  final bool petsAllowed;
  final List<String> amenities;

  @override
  State<_RentalInformationCard> createState() => _RentalInformationCardState();
}

class _RentalInformationCardState extends State<_RentalInformationCard> {
  int? _expandedIndex; // 0: Rent, 1: Rules, 2: Amenities

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(_kThousandsRe, (m) => '${m[1]},');

  static Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _div() =>
      const Divider(height: 1, thickness: 0.8, color: AppColors.fieldFill);

  Widget _buildItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                // Soft teal icon container
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.tenantFillCyan,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 18,
                    color: AppColors.primaryCyan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Chevron button
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: !isExpanded
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.slate200.withValues(alpha: 0.6),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Label (no chevron)
          const Text(
            'Rental Information',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              letterSpacing: -0.2,
            ),
          ),
            const SizedBox(height: 12),
            // Item 1: Rent & Capacity
            _buildItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Rent & Capacity',
              subtitle:
                  '₱${_fmt(widget.monthlyRent)} / month  ·  Max ${widget.maxOccupants} ${widget.maxOccupants == 1 ? 'occupant' : 'occupants'}',
              isExpanded: _expandedIndex == 0,
              onToggle: () =>
                  setState(() => _expandedIndex = _expandedIndex == 0 ? null : 0),
              children: [
                _row('Monthly rent', '₱${_fmt(widget.monthlyRent)}'),
                _div(),
                _row(
                  'Security deposit',
                  widget.depositAmount > 0
                      ? '₱${_fmt(widget.depositAmount)}'
                      : 'None',
                ),
                _div(),
                _row(
                  'Advance payment',
                  widget.advanceMonths > 0
                      ? '${widget.advanceMonths} ${widget.advanceMonths == 1 ? 'month' : 'months'}'
                      : 'None',
                ),
                _div(),
                _row(
                  'Maximum occupants',
                  '${widget.maxOccupants} ${widget.maxOccupants == 1 ? 'occupant' : 'occupants'}',
                ),
              ],
            ),

            const Divider(
              height: 16,
              thickness: 0.8,
              color: AppColors.fieldFill,
            ),

            // Item 2: House Rules
            _buildItem(
              icon: Icons.assignment_outlined,
              title: 'House Rules',
              subtitle:
                  '${formatCurfew(widget.curfewHours)}  ·  ${widget.allowedGender}',
              isExpanded: _expandedIndex == 1,
              onToggle: () =>
                  setState(() => _expandedIndex = _expandedIndex == 1 ? null : 1),
              children: [
                _row('Curfew hours', formatCurfew(widget.curfewHours)),
                _div(),
                _row('Gender policy', widget.allowedGender),
                _div(),
                _row(
                  'Smoking policy',
                  widget.smokingAllowed ? 'Allowed' : 'Not allowed',
                ),
                _div(),
                _row(
                  'Pet policy',
                  widget.petsAllowed ? 'Allowed' : 'Not allowed',
                ),
              ],
            ),

            const Divider(
              height: 16,
              thickness: 0.8,
              color: AppColors.fieldFill,
            ),

            // Item 3: Amenities
            _buildItem(
              icon: Icons.grid_view_rounded,
              title: 'Amenities',
              subtitle: widget.amenities.isNotEmpty
                  ? '${widget.amenities.length} amenities available'
                  : 'Standard amenities included',
              isExpanded: _expandedIndex == 2,
              onToggle: () =>
                  setState(() => _expandedIndex = _expandedIndex == 2 ? null : 2),
              children: [
                if (widget.amenities.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final amenity in widget.amenities)
                          _TenantAmenityChip(label: amenity),
                      ],
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No specific amenities listed.',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: AppColors.slate500,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AMENITY CHIP WIDGET (WHITE CONTAINER WITH SUBTLE APP BLUE OUTLINE)
// ─────────────────────────────────────────────────────────────────────────────

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
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOST / OWNER INFORMATION CARD
// ─────────────────────────────────────────────────────────────────────────────

class _HostInformationCard extends StatelessWidget {
  const _HostInformationCard({
    required this.property,
    this.propertyDoc,
  });

  final Map<String, dynamic> property;
  final PropertyDoc? propertyDoc;

  @override
  Widget build(BuildContext context) {
    final ownerName = (property['ownerName'] as String?) ?? 'Property Owner';
    final ownerInitials = (property['ownerInitials'] as String?) ?? 'PO';
    final ownerPhotoUrl = property['ownerPhotoUrl'] as String?;
    final isVerified = property['isVerified'] == true;
    final memberSince = (property['memberSince'] as String?) ?? 'RentEase';
    final propertyCount = (property['propertyCount'] as num?) ?? 1;

    final owner = property['owner'] as UserDoc?;
    final ownerProfile = property['ownerProfile'] as OwnerProfileDoc?;
    final ownerPhone = property['ownerPhone'] as String?;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OwnerDetailScreen(
                  ownerId: (property['ownerId'] as String?) ?? propertyDoc?.ownerId,
                  owner: owner,
                  ownerProfile: ownerProfile,
                  property: propertyDoc,
                  fallbackName: ownerName,
                  phone: ownerPhone,
                  isVerified: isVerified,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hosted by',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View profile',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage: (ownerPhotoUrl != null &&
                              ownerPhotoUrl.isNotEmpty)
                          ? ResizeImage.resizeIfNeeded(236, null, NetworkImage(ownerPhotoUrl))
                          : null,
                      child: (ownerPhotoUrl == null || ownerPhotoUrl.isEmpty)
                          ? Text(
                              ownerInitials,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ownerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.slate900,
                                  ),
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                        size: 11,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Member since $memberSince · $propertyCount ${propertyCount == 1 ? 'property' : 'properties'}',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── PROPERTY REVIEWS CARD (NON-EXPANDABLE, SCROLLABLE 5 ROWS) ─────────────────

class _PropertyReviewsCard extends StatefulWidget {
  const _PropertyReviewsCard({
    required this.propertyId,
    this.parentPropertyId,
    this.ownerId,
    this.propertyName,
    this.title,
    this.inquiryId,
    this.initialAvgRating,
    this.initialTotalRatings,
  });

  final String propertyId;
  final String? parentPropertyId;
  final String? ownerId;
  final String? propertyName;
  final String? title;
  final String? inquiryId;
  final double? initialAvgRating;
  final int? initialTotalRatings;

  @override
  State<_PropertyReviewsCard> createState() => _PropertyReviewsCardState();
}

class _PropertyReviewData {
  const _PropertyReviewData({
    required this.raterName,
    required this.stars,
    required this.dateStr,
    this.comment,
  });

  final String raterName;
  final int stars;
  final String dateStr;
  final String? comment;
}

class _PropertyReviewsCardState extends State<_PropertyReviewsCard> {
  late final ScrollController _listScrollController;
  bool _isLoading = true;
  List<_PropertyReviewData> _reviews = [];
  // Header numbers: the property doc's stored counters (never the page).
  double _avgRating = 0.0;
  int _totalCount = 0;
  // Pagination of the written-review list.
  DocumentSnapshot<Object?>? _lastDoc;
  bool _hasMore = false;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _listScrollController = ScrollController()..addListener(_onListScroll);
    _avgRating = widget.initialAvgRating ?? 0.0;
    _totalCount = widget.initialTotalRatings ?? 0;
    _loadReviews();
  }

  @override
  void didUpdateWidget(covariant _PropertyReviewsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _avgRating = widget.initialAvgRating ?? 0.0;
    _totalCount = widget.initialTotalRatings ?? 0;
    if (oldWidget.propertyId != widget.propertyId ||
        oldWidget.parentPropertyId != widget.parentPropertyId ||
        oldWidget.ownerId != widget.ownerId ||
        oldWidget.inquiryId != widget.inquiryId) {
      _lastDoc = null;
      _hasMore = false;
      _loadReviews();
    }
  }

  @override
  void dispose() {
    _listScrollController
      ..removeListener(_onListScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadReviews({bool more = false}) async {
    final pid = widget.propertyId.trim();
    if (pid.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (more && (_loadingMore || !_hasMore)) return;
    _loadingMore = more;

    try {
      // One page of this listing's tenant reviews, newest first. The header
      // average/count come from the property doc's counters (initial*), not
      // from the loaded page.
      final tenantDocs =
          await PropertyRatingsAggregator.fetchRatingDocsForProperty(
        firestore: FirebaseFirestore.instance,
        propertyId: pid,
        startAfter: more ? _lastDoc : null,
      );
      _hasMore =
          tenantDocs.length >= PropertyRatingsAggregator.reviewsPageSize;
      if (tenantDocs.isNotEmpty) _lastDoc = tenantDocs.last;

      if (!mounted) return;

      if (tenantDocs.isEmpty) {
        if (mounted) {
          setState(() {
            if (!more) _reviews = [];
            _isLoading = false;
          });
        }
        _loadingMore = false;
        return;
      }

      final raterIds = <String>{};
      for (final doc in tenantDocs) {
        final raterId = doc.data()['raterId'] as String?;
        if (raterId != null && raterId.isNotEmpty) {
          raterIds.add(raterId);
        }
      }

      final raterNames = <String, String>{};
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final currentUserName = FirebaseAuth.instance.currentUser?.displayName;
      if (currentUid != null) {
        raterNames[currentUid] =
            (currentUserName?.isNotEmpty == true) ? currentUserName! : 'You';
      }

      if (raterIds.isNotEmpty) {
        final idsList = raterIds.where((id) => id != currentUid).toList();
        for (var i = 0; i < idsList.length; i += 10) {
          final chunk = idsList.sublist(
              i, (i + 10 > idsList.length) ? idsList.length : i + 10);
          try {
            final usersSnap = await FirebaseFirestore.instance
                .collection(FirestoreCollections.users)
                .where(FieldPath.documentId, whereIn: chunk)
                .get();
            for (final u in usersSnap.docs) {
              final d = u.data();
              final fn = (d['firstName'] as String?)?.trim() ?? '';
              final ln = (d['lastName'] as String?)?.trim() ?? '';
              final name = '$fn $ln'.trim();
              if (name.isNotEmpty) {
                raterNames[u.id] = name;
              }
            }
          } catch (e) {
            debugPrint('Error fetching rater user docs: $e');
          }
        }
      }

      final loaded = <_PropertyReviewData>[];
      for (final doc in tenantDocs) {
        final data = doc.data();
        final r = RatingDoc.fromSnapshot(doc);
        final stars = r.stars > 0
            ? r.stars.toInt().clamp(1, 5)
            : parseNum(data['stars'], 5).toInt().clamp(1, 5);

        String dateStr = 'Recent';
        final at =
            r.createdAt?.toDate() ?? parseTimestamp(data['createdAt'])?.toDate();
        if (at != null) {
          const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          dateStr = '${months[at.month - 1]} ${at.day}, ${at.year}';
        }

        final comment = (r.review?.trim().isNotEmpty ?? false)
            ? r.review!.trim()
            : ((data['comment'] as String?)?.trim().isNotEmpty ?? false)
                ? (data['comment'] as String).trim()
                : ((data['feedback'] as String?)?.trim().isNotEmpty ?? false)
                    ? (data['feedback'] as String).trim()
                    : null;

        loaded.add(
          _PropertyReviewData(
            raterName: raterNames[r.raterId] ??
                (r.raterId == currentUid ? 'You' : 'Verified Tenant'),
            stars: stars,
            dateStr: dateStr,
            comment: comment,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _reviews = more ? [..._reviews, ...loaded] : loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading property reviews: $e');
      if (mounted) setState(() => _isLoading = false);
    }
    _loadingMore = false;
  }

  // Load the next page when the reviews list is scrolled near its end.
  void _onListScroll() {
    final pos = _listScrollController.position;
    if (_hasMore && !_loadingMore && pos.pixels >= pos.maxScrollExtent - 48) {
      _loadReviews(more: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double effectiveAvg = _avgRating > 0
        ? _avgRating
        : (widget.initialAvgRating ?? 0.0);
    final int effectiveCount = _totalCount > 0
        ? _totalCount
        : (widget.initialTotalRatings ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldFill, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Property reviews',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              if (!_isLoading && effectiveCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.warningFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.matchMedium,
                        size: 15,
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        '${effectiveAvg.toStringAsFixed(1)} ($effectiveCount)',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.8, color: AppColors.fieldFill),
          const SizedBox(height: 12),

          SizedBox(
            height: 260,
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.sky400,
                      ),
                    ),
                  )
                : _reviews.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 32,
                              color: AppColors.slate400.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No reviews yet for this property',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Reviews from verified tenants will appear here.',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                color: AppColors.slate400,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Scrollbar(
                        controller: _listScrollController,
                        thumbVisibility: _reviews.length > 2,
                        child: ListView.separated(
                          controller: _listScrollController,
                          primary: false,
                          padding: const EdgeInsets.only(right: 6),
                          itemCount: _reviews.length,
                          separatorBuilder: (_, _) => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              height: 1,
                              thickness: 0.6,
                              color: AppColors.fieldFill,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final rev = _reviews[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        rev.raterName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.slate900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      rev.dateStr,
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 11,
                                        color: AppColors.slate400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: List.generate(5, (i) {
                                    return Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: i < rev.stars
                                          ? AppColors.matchMedium
                                          : AppColors.slate200,
                                    );
                                  }),
                                ),
                                if (rev.comment != null &&
                                    rev.comment!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    rev.comment!.trim(),
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 12.5,
                                      height: 1.35,
                                      color: AppColors.slate600,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Merges freshly loaded [detail] into the [current] property map.
///
/// Match-status keys passed in by the caller are preserved, and a repository
/// non-match ([repoSaysNonMatch]) always wins: bScore is forced to 0 so the
/// availability-derived fallback can never re-enable Send Inquiry.
/// Marks the match status as known (`matchKnown: true`) only when the
/// repository evaluated the match ([repoKnowsMatch]) or the caller already
/// supplied a known status; otherwise `matchKnown` stays false.
Map<String, dynamic> mergePropertyDetail({
  required Map<String, dynamic> current,
  required Map<String, dynamic> detail,
  required bool repoSaysNonMatch,
  bool repoKnowsMatch = true,
}) {
  final wasNonMatch = current['isNonMatch'];
  final wasFilterMatch = current['isFilterMatch'];
  final sessionReasons = current['mismatchReasons'];
  final wasOutside = current['isOutsidePreference'];
  final bExcess = current['budgetExcess'];
  final dExcess = current['distanceExcess'];
  final bScore = current['bScore'];

  return {
    ...current,
    ...detail,
    if (wasNonMatch != null) ...{'isNonMatch': wasNonMatch},
    if (wasFilterMatch != null) ...{'isFilterMatch': wasFilterMatch},
    if (sessionReasons != null) ...{'mismatchReasons': sessionReasons},
    if (wasOutside != null) ...{'isOutsidePreference': wasOutside},
    if (bExcess != null) ...{'budgetExcess': bExcess},
    if (dExcess != null) ...{'distanceExcess': dExcess},
    // Never let the availability-derived fallback re-enable a property that
    // was passed in with bScore 0.
    if (bScore != null &&
        ((wasNonMatch == false && wasFilterMatch != true) ||
            (bScore is num && bScore == 0)))
      ...{'bScore': bScore},
    if (detail['bScore'] is num && detail['bScore'] == 0) ...{'bScore': 0},
    if (repoSaysNonMatch) ...{
      'bScore': 0,
      'isNonMatch': true,
      if (detail['mismatchReasons'] != null)
        'mismatchReasons': detail['mismatchReasons'],
    },
    'matchKnown':
        repoKnowsMatch || repoSaysNonMatch || current['matchKnown'] != false,
  };
}
