import 'dart:ui' show ImageFilter;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../core/firestore/tenant_profile_loader.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/app_svg_icon.dart';
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
final RegExp _kWhitespaceRe = RegExp(r'\s+');

/// The detail-screen heart: transparent glass circular badge on the hero image,
/// filled destructive when saved. Rebuilds only when this property's saved flag changes.
class _SaveHeart extends StatelessWidget {
  const _SaveHeart({
    required this.propertyId,
    required this.cubit,
    required this.onTap,
  });

  final String propertyId;
  final HomeCubit? cubit;
  final void Function(HomeCubit? cubit) onTap;

  @override
  Widget build(BuildContext context) {
    final cubit = this.cubit;
    Widget button(bool saved) => Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => onTap(cubit),
        customBorder: const CircleBorder(),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.scrim.withValues(alpha: 0.25),
                border: Border.all(
                  color: AppColors.surface.withValues(alpha: 0.35),
                  width: 0.6,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                saved ? Icons.favorite : Icons.favorite_border,
                color: saved ? AppColors.destructive : AppColors.surface,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );

    if (cubit == null) return button(false);
    return BlocBuilder<HomeCubit, HomeState>(
      bloc: cubit,
      buildWhen: (a, b) =>
          a.savedIds.contains(propertyId) != b.savedIds.contains(propertyId),
      builder: (_, state) => button(state.savedIds.contains(propertyId)),
    );
  }
}

/// Tenant Property Detail screen designed with the modern Property Management style:
/// Hero photo carousel with thumbnails, main overview card, view-only expandable sections
/// for Rent & Capacity, House Rules, and Amenities, reviews redirect, and fixed bottom action.
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
          pDoc = PropertyDoc.fromSnapshot(snap);
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

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(_kThousandsRe, (m) => '${m[1]},');

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
    final monthlyRent = (_property['monthlyRent'] as num?) ?? 0;
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

    final propertyDoc = _resolvePropertyDoc();
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
                // Top Custom Header with Back Button and Title
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
                      Text(
                        'Property Details',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.appColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
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
                    ),
                    const SizedBox(height: 14),

                    // ── 3. Expandable Card 1: Rent & Capacity ─────────────
                    _ExpandableSection(
                      svgIcon: AppSvgIcons.rentAndCapacity,
                      title: 'Rent & Capacity',
                      subtitle:
                          '₱${_fmt(monthlyRent)} / month  ·  Max $maxOccupants ${maxOccupants == 1 ? 'occupant' : 'occupants'}',
                      children: [
                        _detailRow('Monthly rent', '₱${_fmt(monthlyRent)}'),
                        _divider(),
                        _detailRow(
                          'Security deposit',
                          depositAmount > 0
                              ? '₱${_fmt(depositAmount)}'
                              : 'None',
                        ),
                        _divider(),
                        _detailRow(
                          'Advance payment',
                          advanceMonths > 0
                              ? '$advanceMonths ${advanceMonths == 1 ? 'month' : 'months'}'
                              : 'None',
                        ),
                        _divider(),
                        _detailRow(
                          'Maximum occupants',
                          '$maxOccupants ${maxOccupants == 1 ? 'occupant' : 'occupants'}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── 4. Expandable Card 2: House Rules ─────────────────
                    _ExpandableSection(
                      svgIcon: AppSvgIcons.houseRules,
                      title: 'House Rules',
                      subtitle:
                          '${formatCurfew(curfewHours)}  ·  $allowedGender',
                      children: [
                        _detailRow('Curfew hours', formatCurfew(curfewHours)),
                        _divider(),
                        _detailRow('Gender policy', allowedGender),
                        _divider(),
                        _detailRow(
                          'Smoking policy',
                          smokingAllowed ? 'Allowed' : 'Not allowed',
                        ),
                        _divider(),
                        _detailRow(
                          'Pet policy',
                          petsAllowed ? 'Allowed' : 'Not allowed',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── 5. Expandable Card 3: Amenities ───────────────────
                    _ExpandableSection(
                      svgIcon: AppSvgIcons.amenities,
                      title: 'Amenities',
                      subtitle: amenities.isNotEmpty
                          ? '${amenities.length} amenities available'
                          : 'Standard amenities included',
                      children: [
                        if (amenities.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final amenity in amenities)
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
                    const SizedBox(height: 14),

                    // ── 6. Host / Owner Information Card ───────────────────
                    _HostInformationCard(
                      property: _property,
                      propertyDoc: propertyDoc,
                    ),
                    const SizedBox(height: 14),

                    // ── 6.1 Property Reviews Card (Non-expandable, scrollable) ─
                    _PropertyReviewsCard(
                      propertyId: propertyDoc.propertyId,
                      parentPropertyId: propertyDoc.parentPropertyId,
                      inquiryId: widget.inquiryId,
                      onRatingLoaded: (avg, totalCount) {
                        if (mounted &&
                            ((_property['avgRating'] as num?)?.toDouble() != avg ||
                                (_property['totalRatings'] as num?)?.toInt() != totalCount)) {
                          setState(() {
                            _property['avgRating'] = avg;
                            _property['totalRatings'] = totalCount;
                          });
                        }
                      },
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

  static Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13.5,
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
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _divider() =>
      const Divider(height: 1, thickness: 0.8, color: AppColors.fieldFill);
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
// PHOTO CAROUSEL WITH THUMBNAILS (MATCHING PROPERTY MANAGER SCREEN)
// ─────────────────────────────────────────────────────────────────────────────

class _PropertyPhotoGallerySection extends StatefulWidget {
  const _PropertyPhotoGallerySection({
    required this.photos,
    required this.seed,
    required this.propertyId,
    required this.cubit,
    required this.onSavedToggle,
    required this.matchPercent,
    this.tenantCi,
    required this.matchDotColor,
    required this.isGuest,
    required this.isNonMatch,
    this.isFilterMatch = false,
  });

  final List<String> photos;
  final int seed;
  final String propertyId;
  final HomeCubit? cubit;
  final VoidCallback onSavedToggle;
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

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final photoCount = photos.length;
    final safeIndex = photoCount > 0
        ? _selectedPhotoIndex.clamp(0, photoCount - 1)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Large Rounded Image (Swipeable PageView)
        Container(
          height: 210,
          width: double.infinity,
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

              // Top-left: Match score / Mismatch badge (transparent glass, matching home cards)
              Positioned(
                top: 10,
                left: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.scrim.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (widget.isNonMatch || widget.isFilterMatch)
                                  ? AppColors.amberPrimary.withValues(alpha: 0.6)
                                  : (!widget.isGuest && widget.matchPercent > 0)
                                      ? widget.matchDotColor.withValues(alpha: 0.45)
                                      : AppColors.surface.withValues(alpha: 0.25),
                              width: 0.6,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.isNonMatch) ...[
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 10.5,
                                  color: AppColors.amberPrimary,
                                ),
                                const SizedBox(width: 3),
                                const Text(
                                  "Doesn't match",
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.surface,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ] else if (widget.isFilterMatch) ...[
                                const Icon(
                                  Icons.tune_rounded,
                                  size: 10.5,
                                  color: AppColors.amberPrimary,
                                ),
                                const SizedBox(width: 3.5),
                                const Text(
                                  'Filter Match',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.surface,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ] else if (!widget.isGuest &&
                                  widget.matchPercent > 0) ...[
                                Text(
                                  '${widget.matchPercent}% Match',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.surface,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ] else if (!widget.isGuest) ...[
                                Text(
                                  (widget.tenantCi != null && widget.tenantCi! > 0)
                                      ? '${(widget.tenantCi! * 100).round()}% Match'
                                      : '0% Match',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.surface,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ] else ...[
                                Icon(
                                  Icons.lock_outline,
                                  size: 9.5,
                                  color: AppColors.onInk.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 3),
                                const Text(
                                  'Match',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.surface,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!widget.isGuest && !widget.isNonMatch && (widget.matchPercent > 0 || (widget.tenantCi != null && widget.tenantCi! > 0))) ...[
                      const SizedBox(width: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.scrim.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.indigo400.withValues(alpha: 0.6),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              'ci=${(widget.tenantCi ?? (widget.matchPercent / 100.0)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.indigo200,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Top-right: Like / Heart button (transparent glass circle badge)
              Positioned(
                top: 10,
                right: 10,
                child: _SaveHeart(
                  propertyId: widget.propertyId,
                  cubit: widget.cubit,
                  onTap: (_) => widget.onSavedToggle(),
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
                          color: AppColors.scrim.withValues(alpha: 0.28),
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
                              size: 10.5,
                              color: AppColors.surface,
                            ),
                            const SizedBox(width: 3.5),
                            Text(
                              photoCount > 1
                                  ? '${safeIndex + 1} / $photoCount'
                                  : '$photoCount',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 9.5,
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
        ),

        if (photoCount > 1) ...[
          const SizedBox(height: 10),
          // Horizontal Thumbnails Row
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == safeIndex;
                final thumbUrl = photos[index];

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPhotoIndex = index);
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            thumbUrl,
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
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.slate200,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN OVERVIEW CARD (NAME, LOCATION, REVIEWS REDIRECT, RENT)
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
  });

  final String displayName;
  final String displayType;
  final String address;
  final num monthlyRent;
  final PropertyDoc propertyDoc;
  final double? avgRating;
  final int? totalRatings;
  final VoidCallback? onAddressTap;

  @override
  State<_PropertyMainOverviewCard> createState() => _PropertyMainOverviewCardState();
}

class _PropertyMainOverviewCardState extends State<_PropertyMainOverviewCard> {
  bool _isAddressExpanded = false;

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(_kThousandsRe, (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final displayName = widget.displayName;
    final displayType = widget.displayType;
    final address = widget.address;
    final monthlyRent = widget.monthlyRent;
    final onAddressTap = widget.onAddressTap;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Address Row with Theme Blue Pin (Click address to show full / hide, Click Map to open Map View)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pin Icon (Taps to open Map View)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAddressTap,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 1.5),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 14.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 5),

                // Address Text: 1 line with ellipsis by default, tap to expand to full, tap again to hide
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
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.slate500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Map navigation link (plain blue text, no badge)
                if (onAddressTap != null)
                  InkWell(
                    onTap: onAddressTap,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Map',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
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
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Star rating & review count row
          Builder(
            builder: (context) {
              final double avg = (widget.avgRating != null && widget.avgRating! > 0)
                  ? widget.avgRating!
                  : ((widget.propertyDoc.avgRating != null && widget.propertyDoc.avgRating! > 0)
                      ? widget.propertyDoc.avgRating!.toDouble()
                      : 0.0);
              final int count = widget.totalRatings ?? widget.propertyDoc.totalRatings?.toInt() ?? 0;
              final hasReviews = avg > 0 || count > 0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 16.5,
                    color: AppColors.matchMedium,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasReviews ? avg.toStringAsFixed(1) : '0.0',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    count > 0
                        ? '($count ${count == 1 ? 'review' : 'reviews'})'
                        : '(No reviews yet)',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 0.8, color: AppColors.fieldFill),
          const SizedBox(height: 14),

          // Details Row: Property Type on left, Rent on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const AppSvgIcon(
                      svgString: AppSvgIcons.propertyType,
                      size: 16,
                      color: AppColors.slate900,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        displayType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₱${_fmt(monthlyRent)}',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Text(
                    ' / month',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE EXPANDABLE VIEW-ONLY SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandableSection extends StatefulWidget {
  const _ExpandableSection({
    required this.svgIcon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String svgIcon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: AppSvgIcon(
                        svgString: widget.svgIcon,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Container(
                        width: 30,
                        height: 30,
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
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_isExpanded
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.fieldFill,
                        ),
                        const SizedBox(height: 10),
                        ...widget.children,
                      ],
                    ),
                  ),
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
    this.inquiryId,
    this.onRatingLoaded,
  });

  final String propertyId;
  final String? parentPropertyId;
  final String? inquiryId;
  final void Function(double avg, int count)? onRatingLoaded;

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
  bool _isLoading = true;
  List<_PropertyReviewData> _reviews = [];
  double _avgRating = 0.0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final pid = widget.propertyId;
    if (pid.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final targetIds = <String>{pid};
      if (widget.parentPropertyId != null && widget.parentPropertyId!.isNotEmpty) {
        targetIds.add(widget.parentPropertyId!);
      }

      final docsMap = <String, DocumentSnapshot<Map<String, dynamic>>>{};

      // 1. By propertyId
      try {
        final snap = await FirebaseFirestore.instance
            .collection(FirestoreCollections.ratings)
            .where('propertyId', whereIn: targetIds.take(10).toList())
            .get();
        for (final doc in snap.docs) {
          docsMap[doc.id] = doc;
        }
      } catch (e) {
        debugPrint('Error querying ratings by propertyId: $e');
      }

      // 2. By parentPropertyId (if targetIds has parent)
      try {
        final parentSnap = await FirebaseFirestore.instance
            .collection(FirestoreCollections.ratings)
            .where('parentPropertyId', whereIn: targetIds.take(10).toList())
            .get();
        for (final doc in parentSnap.docs) {
          docsMap[doc.id] = doc;
        }
      } catch (e) {
        debugPrint('Error querying ratings by parentPropertyId: $e');
      }

      // 3. By inquiryId (if thread inquiryId passed, ensures user's rated stay in this thread always shows)
      if (widget.inquiryId != null && widget.inquiryId!.isNotEmpty) {
        try {
          final inqSnap = await FirebaseFirestore.instance
              .collection(FirestoreCollections.ratings)
              .where('inquiryId', isEqualTo: widget.inquiryId)
              .get();
          for (final doc in inqSnap.docs) {
            docsMap[doc.id] = doc;
          }
        } catch (e) {
          debugPrint('Error querying ratings by inquiryId: $e');
        }
      }

      if (!mounted) return;

      // Only include reviews written by tenants FOR the property.
      // Never show the owner's review of the tenant in Property Details.
      final tenantDocs = docsMap.values.where((doc) {
        final role = doc.data()?['raterRole'] as String?;
        return role == 'tenant';
      }).toList();

      if (tenantDocs.isEmpty) {
        setState(() {
          _reviews = [];
          _avgRating = 0.0;
          _totalCount = 0;
          _isLoading = false;
        });
        widget.onRatingLoaded?.call(0.0, 0);
        return;
      }

      final raterIds = <String>{};
      for (final doc in tenantDocs) {
        final raterId = doc.data()?['raterId'] as String?;
        if (raterId != null && raterId.isNotEmpty) {
          raterIds.add(raterId);
        }
      }

      final raterNames = <String, String>{};
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final currentUserName = FirebaseAuth.instance.currentUser?.displayName;
      if (currentUid != null) {
        raterNames[currentUid] = (currentUserName?.isNotEmpty == true) ? currentUserName! : 'You';
      }

      if (raterIds.isNotEmpty) {
        try {
          final usersSnap = await FirebaseFirestore.instance
              .collection(FirestoreCollections.users)
              .where(FieldPath.documentId, whereIn: raterIds.take(10).toList())
              .get();
          for (final u in usersSnap.docs) {
            final d = u.data();
            final fn = (d['firstName'] as String?)?.trim() ?? '';
            final ln = (d['lastName'] as String?)?.trim() ?? '';
            final name = '$fn $ln'.trim();
            if (name.isNotEmpty) {
              raterNames[u.id] = (u.id == currentUid) ? '$name (You)' : name;
            }
          }
        } catch (e) {
          debugPrint('Error fetching rater user docs: $e');
        }
      }

      final loaded = <_PropertyReviewData>[];
      num totalStars = 0;
      for (final doc in tenantDocs) {
        final r = RatingDoc.fromSnapshot(doc);
        totalStars += r.stars;

        String dateStr = 'Recent';
        final at = r.createdAt?.toDate();
        if (at != null) {
          const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          dateStr = '${months[at.month - 1]} ${at.day}, ${at.year}';
        }

        loaded.add(
          _PropertyReviewData(
            raterName: raterNames[r.raterId] ?? (r.raterId == currentUid ? 'You' : 'Tenant'),
            stars: r.stars.toInt().clamp(1, 5),
            dateStr: dateStr,
            comment: r.review,
          ),
        );
      }

      if (mounted) {
        final computedAvg = loaded.isNotEmpty ? (totalStars / loaded.length).toDouble() : 0.0;
        setState(() {
          _reviews = loaded;
          _totalCount = loaded.length;
          _avgRating = computedAvg;
          _isLoading = false;
        });
        widget.onRatingLoaded?.call(computedAvg, loaded.length);
      }
    } catch (e) {
      debugPrint('Error loading property reviews: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              if (!_isLoading && _totalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
                        '${_avgRating.toStringAsFixed(1)} ($_totalCount)',
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
                        thumbVisibility: true,
                        child: ListView.separated(
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      rev.raterName,
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.slate900,
                                      ),
                                    ),
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
