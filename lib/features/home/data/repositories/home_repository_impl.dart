import '../../../../core/firestore/models/models.dart';
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
      if (property == null) continue;
      listings.add(
        Listing.fromMatch(match: match, property: property, imageSeed: i % 5 + 1),
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

    final owner = await _remote.fetchUser(property.ownerId);
    final ownerProfile = await _remote.fetchOwnerProfile(property.ownerId);

    final ownerName = owner != null
        ? '${owner.firstName} ${owner.lastName}'.trim()
        : 'Property owner';
    final ownerInitials = _initialsFor(owner?.firstName, owner?.lastName);

    return {
      'propertyId': property.propertyId,
      'title': property.title,
      'address': property.address,
      'monthlyRent': property.monthlyRent,
      'distance': match?.distanceKm ?? 0,
      'amenityScore': property.amenityScore ?? property.amenityList.length,
      'tenantCi': match?.tenantCi ?? 0,
      'tenantRank': match?.tenantRank ?? 0,
      'isVerified': property.isVerified,
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
      // Only eligible (bScore = 1) properties reach this screen from the
      // home feed — CLAUDE.md rule 2/8: Send Inquiry is absent, never
      // disabled, so there is no "outside preference" variant to render here.
      'bScore': 1,
      'isOutsidePreference': false,
      'vacancyStatus': property.vacancyStatus,
      'isAvailable': property.isAvailable,
      'latitude': property.location.latitude,
      'longitude': property.location.longitude,
    };
  }

  String _initialsFor(String? first, String? last) {
    final f = (first?.isNotEmpty ?? false) ? first![0] : '';
    final l = (last?.isNotEmpty ?? false) ? last![0] : '';
    final initials = '$f$l'.toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  String _formatMemberSince(DateTime? createdAt) {
    if (createdAt == null) return 'RentEase';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[createdAt.month - 1]} ${createdAt.year}';
  }
}
