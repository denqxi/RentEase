import '../../../../core/firestore/models/models.dart';
import '../../../../core/utils/distance_utils.dart';
import '../../../matching/domain/services/filtering_service.dart';
import '../../../matching/domain/entities/mismatch_reason.dart';
import '../../domain/repositories/home_repository.dart';
import '../../model/listing.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({HomeRemoteDataSource? remote})
    : _remote = remote ?? HomeRemoteDataSource();

  final HomeRemoteDataSource _remote;

  @override
  Future<List<Listing>> fetchCompatibleListings(String tenantId) async {
    final matches = await _remote.fetchEligibleMatches(tenantId);
    final listings = <Listing>[];
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final property = await _remote.fetchProperty(match.propertyId);
      // A match can outlive its property (delisted since filtering last
      // ran) — skip rather than show a broken card; the next
      // FilteringService.runFiltering() pass will clean the stale match up.
      if (property == null || !property.isAvailable) continue;
      listings.add(
        Listing.fromMatch(
          match: match,
          property: property,
          imageSeed: i % 5 + 1,
        ),
      );
    }
    return listings;
  }

  @override
  Future<Map<String, dynamic>?> fetchPropertyDetail({
    required String tenantId,
    required String propertyId,
  }) async {
    final matches = await _remote.fetchEligibleMatches(tenantId);
    MatchDoc? match;
    for (final m in matches) {
      if (m.propertyId == propertyId) {
        match = m;
        break;
      }
    }
    final property = await _remote.fetchProperty(propertyId);
    if (property == null) return null;

    final (owner, ownerProfile) = await (
      _remote.fetchUser(property.ownerId),
      _remote.fetchOwnerProfile(property.ownerId),
    ).wait;
    final map = _propertyMap(property, match, owner, ownerProfile);
    if (match != null) return map;

    // No eligible match (e.g. saved from Other listings, or it went stale):
    // explain why, exactly as fetchNonMatchingResults does. bScore stays 0
    // either way, so Send Inquiry is absent; an empty reasons list (it now
    // passes, cached row not written yet) is a plain view-only detail.
    final (profile, tenantUser) = await (
      _remote.fetchTenantProfile(tenantId),
      _remote.fetchUser(tenantId),
    ).wait;
    if (profile == null) return map;
    final km = DistanceUtils.kmBetween(profile.poiLatLng, property.location);
    final reasons = FilteringService.explainMismatch(
      tenantGender: tenantUser?.gender ?? '',
      tenant: profile,
      property: property,
      distanceKm: km,
    );
    if (reasons.isEmpty) return map;
    return {
      ...map,
      'distance': _roundKm(km),
      'bScore': 0,
      'matchId': null,
      'isNonMatch': true,
      'mismatchReasons': reasons,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSearchResults(String tenantId) async {
    // Already ordered by tenantCi desc (see HomeRemoteDataSource).
    final matches = await _remote.fetchEligibleMatches(tenantId);
    final properties = await Future.wait(
      matches.map((m) => _remote.fetchProperty(m.propertyId)),
    );

    // One owner can list several properties — fetch each owner once.
    final ownerIds = {
      for (final p in properties)
        if (p != null) p.ownerId,
    };
    final owners = <String, (UserDoc?, OwnerProfileDoc?)>{};
    await Future.wait(
      ownerIds.map((id) async {
        owners[id] = await (
          _remote.fetchUser(id),
          _remote.fetchOwnerProfile(id),
        ).wait;
      }),
    );

    return [
      for (var i = 0; i < matches.length; i++)
        if (properties[i] case final property? when property.isAvailable)
          _propertyMap(
            property,
            matches[i],
            owners[property.ownerId]?.$1,
            owners[property.ownerId]?.$2,
          ),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchNonMatchingResults({
    required String tenantId,
    required TenantProfileDoc profile,
    required Set<String> excludePropertyIds,
    int limit = 50,
    int? displayLimit,
  }) async {
    final (properties, tenantUser) = await (
      _remote.fetchAvailableProperties(limit: limit),
      _remote.fetchUser(tenantId),
    ).wait;
    final tenantGender = tenantUser?.gender ?? '';

    final candidates = <(PropertyDoc, double, List<MismatchReason>)>[];
    for (final property in properties) {
      if (excludePropertyIds.contains(property.propertyId)) continue;
      final km = DistanceUtils.kmBetween(profile.poiLatLng, property.location);
      final reasons = FilteringService.explainMismatch(
        tenantGender: tenantGender,
        tenant: profile,
        property: property,
        distanceKm: km,
      );
      // Passes every rule: a match whose cached row is just not written yet
      // (the next matching run adds it). Not a non-match.
      if (reasons.isEmpty) continue;
      candidates.add((property, km, reasons));
    }

    var shown = candidates;
    if (displayLimit != null && candidates.length > displayLimit) {
      // Fewest reasons first, ties newest-first (the fetch order); the index
      // keeps the sort stable.
      final indexed = candidates.indexed.toList()
        ..sort((a, b) {
          final byReasons = a.$2.$3.length.compareTo(b.$2.$3.length);
          return byReasons != 0 ? byReasons : a.$1.compareTo(b.$1);
        });
      shown = [for (final e in indexed.take(displayLimit)) e.$2];
    }

    final owners = <String, (UserDoc?, OwnerProfileDoc?)>{};
    await Future.wait(
      {for (final c in shown) c.$1.ownerId}.map((id) async {
        owners[id] = await (
          _remote.fetchUser(id),
          _remote.fetchOwnerProfile(id),
        ).wait;
      }),
    );

    return [
      for (final (property, km, reasons) in shown)
        {
          ..._propertyMap(
            property,
            null,
            owners[property.ownerId]?.$1,
            owners[property.ownerId]?.$2,
          ),
          'distance': _roundKm(km),
          'bScore': 0,
          'matchId': null,
          'isNonMatch': true,
          'mismatchReasons': reasons,
        },
    ];
  }

  @override
  Future<List<Listing>> fetchGuestListings({int limit = 20}) async {
    final properties = await _remote.fetchAvailableProperties(limit: limit);
    return [
      for (final (i, p) in properties.indexed)
        Listing.fromProperty(property: p, imageSeed: i % 5 + 1),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGuestSearchResults({
    int limit = 20,
  }) async {
    final properties = await _remote.fetchAvailableProperties(limit: limit);
    return [for (final p in properties) _propertyMap(p, null, null, null)];
  }

  @override
  Future<Map<String, dynamic>?> fetchGuestPropertyDetail(
    String propertyId,
  ) async {
    final property = await _remote.fetchProperty(propertyId);
    if (property == null || !property.isAvailable) return null;
    return _propertyMap(property, null, null, null);
  }

  @override
  Future<TenantProfileDoc?> fetchTenantProfile(String tenantId) =>
      _remote.fetchTenantProfile(tenantId);

  /// The one property-map shape shared by the detail screen, Search and
  /// Search's map view.
  Map<String, dynamic> _propertyMap(
    PropertyDoc property,
    MatchDoc? match,
    UserDoc? owner,
    OwnerProfileDoc? ownerProfile,
  ) {
    final ownerName = owner != null
        ? '${owner.firstName} ${owner.lastName}'.trim()
        : 'Property owner';
    final ownerInitials = _initialsFor(owner?.firstName, owner?.lastName);

    return {
      'propertyId': property.propertyId,
      'ownerId': property.ownerId,
      // Needed to open an inquiry for this exact pairing (InquiryService).
      'matchId': match?.matchId,
      'title': property.title,
      'photoUrl': property.photos.isNotEmpty ? property.photos.first : null,
      'photos': List<String>.from(property.photos),
      'address': property.address,
      'monthlyRent': property.monthlyRent,
      'distance': _roundKm(match?.distanceKm ?? 0),
      'amenityScore': property.amenityScore ?? property.amenityList.length,
      'tenantCi': match?.tenantCi ?? 0,
      'tenantRank': match?.tenantRank ?? 0,
      // The owner's real status (the denormalised property flag can lag
      // behind admin approval). Drives the Verified badge only.
      'isVerified': ownerProfile?.verificationStatus == 'verified',
      'allowedGender': property.allowedGender,
      'smokingAllowed': property.smokingAllowed,
      'petsAllowed': property.petsAllowed,
      'curfewHours': property.curfewHours,
      'depositAmount': property.depositAmount,
      'advanceMonths': property.advanceMonths,
      'ownerName': ownerName,
      'ownerInitials': ownerInitials,
      'memberSince': _formatMemberSince(owner?.createdAt?.toDate()),
      'propertyCount': ownerProfile?.propertyCount ?? 1,
      'amenityList': property.amenityList,
      // From the real match: 0 if there is no eligible match (e.g. it went
      // stale since the feed loaded), which hides Send Inquiry entirely —
      // CLAUDE.md rule 2: absent, never disabled. A fully booked listing
      // takes no new inquiries either.
      'bScore': property.isAvailable ? (match?.bScore ?? 0) : 0,
      // Set by Search's session filter only (local state, never saved —
      // CLAUDE.md rule 3); false everywhere else.
      'isOutsidePreference': false,
      'vacancyStatus': property.vacancyStatus,
      'isAvailable': property.isAvailable,
      'latitude': property.location.latitude,
      'longitude': property.location.longitude,
    };
  }

  /// One decimal for display ("2.4 km") — the unrounded value is only needed
  /// by FilteringService's LocationMatch, which reads the match doc directly.
  static double _roundKm(num km) => (km * 10).round() / 10;

  String _initialsFor(String? first, String? last) {
    final f = (first?.isNotEmpty ?? false) ? first![0] : '';
    final l = (last?.isNotEmpty ?? false) ? last![0] : '';
    final initials = '$f$l'.toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  String _formatMemberSince(DateTime? createdAt) {
    if (createdAt == null) return 'RentEase';
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
    return '${months[createdAt.month - 1]} ${createdAt.year}';
  }
}
