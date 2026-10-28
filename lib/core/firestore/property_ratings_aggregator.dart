import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_collections.dart';
import 'models/property_doc.dart';
import 'models/tenant_profile_doc.dart';

/// Star-rating roll-up over a set of `properties` docs, from their stored
/// counters only (`ratingSum` / `totalRatings`, bumped atomically with each
/// tenant rating; see InquiryRemoteDataSource.createRating). No `ratings`
/// reads. `avgRating` is never stored: it is derived here.
///
/// Used for the owner's rating (the owner has NO counter of their own: their
/// rating is the roll-up of their properties) and for a building card that
/// groups several room listings.
class OwnerRatingSummary {
  const OwnerRatingSummary({required this.ratingSum, required this.totalRatings});

  static const empty = OwnerRatingSummary(ratingSum: 0, totalRatings: 0);

  final num ratingSum;
  final int totalRatings;

  bool get hasRatings => totalRatings > 0 && ratingSum > 0;

  /// 0.0 when there are no ratings yet.
  double get average => hasRatings ? (ratingSum / totalRatings).toDouble() : 0.0;

  /// sum(ratingSum) / sum(totalRatings) across [properties].
  ///
  /// - A doc without valid counters (legacy data, never rated) contributes
  ///   nothing: it shows "no rating yet" rather than triggering a scan.
  /// - Duplicate docs (same propertyId) are counted once.
  /// - A room whose parent listing doc is also in [properties] is skipped:
  ///   the parent's counters already include that room's ratings (both are
  ///   bumped by the same rating), so counting both would double-count.
  factory OwnerRatingSummary.fromProperties(Iterable<PropertyDoc> properties) {
    final byId = <String, PropertyDoc>{};
    for (final p in properties) {
      byId.putIfAbsent(p.propertyId, () => p);
    }
    num sum = 0;
    var count = 0;
    for (final p in byId.values) {
      final parent = p.parentPropertyId?.trim() ?? '';
      if (parent.isNotEmpty && parent != p.propertyId && byId.containsKey(parent)) {
        continue;
      }
      final c = countersOf(p);
      if (c == null) continue;
      sum += c.sum;
      count += c.total;
    }
    return OwnerRatingSummary(ratingSum: sum, totalRatings: count);
  }

  /// A tenant's rating from the counters on `tenantProfiles/{uid}` (bumped
  /// atomically with each owner rating). No `ratings` reads. A null profile
  /// or missing / zero / malformed counters give [empty] ("no rating yet").
  factory OwnerRatingSummary.fromTenantProfile(TenantProfileDoc? profile) {
    final total = profile?.totalRatings;
    final sum = profile?.ratingSum;
    if (total == null || sum == null || total <= 0 || sum <= 0) return empty;
    return OwnerRatingSummary(ratingSum: sum, totalRatings: total.toInt());
  }

  /// Valid stored counters of [p], or null (missing, zero or malformed).
  static ({num sum, int total})? countersOf(PropertyDoc p) {
    final total = p.totalRatings;
    final sum = p.ratingSum;
    if (total == null || sum == null || total <= 0 || sum <= 0) return null;
    return (sum: sum, total: total.toInt());
  }
}

/// Rating reads for the property / landlord / owner screens.
///
/// Displays (cards, search, detail, saved, landlord screens) use the counters
/// already on the property docs those screens fetch: zero extra reads.
/// Written-review lists use small, indexed `ratings` queries, newest first,
/// one page ([reviewsPageSize]) at a time.
class PropertyRatingsAggregator {
  PropertyRatingsAggregator._();

  /// Page size for the written-review lists.
  static const int reviewsPageSize = 20;

  /// propertyId -> display title, learned from property docs this app
  /// session already loaded (used to label owner reviews; no extra reads).
  static final Map<String, String> _titleCache = {};

  static void _rememberTitles(Iterable<PropertyDoc> properties) {
    for (final p in properties) {
      final title = p.title.trim().isNotEmpty
          ? p.title.trim()
          : (p.propertyName?.trim() ?? '');
      if (title.isNotEmpty) _titleCache[p.propertyId] = title;
    }
  }

  /// [property] with `avgRating` derived from its stored counters. No reads:
  /// [firestore] and [forceRefresh] are kept only so existing callers
  /// compile unchanged.
  static Future<PropertyDoc> hydrateProperty(
    FirebaseFirestore firestore,
    PropertyDoc property, {
    bool forceRefresh = false,
  }) async =>
      withDerivedAverage(property);

  /// [properties] with `avgRating` derived from their stored counters. No
  /// reads (see [hydrateProperty]).
  static Future<List<PropertyDoc>> hydrateProperties(
    FirebaseFirestore firestore,
    List<PropertyDoc> properties, {
    bool forceRefresh = false,
  }) async =>
      [for (final p in properties) withDerivedAverage(p)];

  /// [p] with `avgRating` = ratingSum / totalRatings when it has valid
  /// counters; unchanged otherwise (legacy / unrated: "no rating yet").
  static PropertyDoc withDerivedAverage(PropertyDoc p) {
    _rememberTitles([p]);
    final c = OwnerRatingSummary.countersOf(p);
    if (c == null) return p;
    return p.withRatings(avgRating: c.sum / c.total);
  }

  /// The owner's rating: roll-up of their properties' counters. Pass the
  /// owner's property docs when the screen already has them (zero reads);
  /// otherwise this runs ONE `properties where ownerId == X` query. Returns
  /// [OwnerRatingSummary.empty] when nothing is readable (e.g. a guest).
  static Future<OwnerRatingSummary> getOwnerRollupRating({
    required FirebaseFirestore firestore,
    required String ownerId,
    List<PropertyDoc>? properties,
  }) async {
    if (properties != null) {
      _rememberTitles(properties);
      return OwnerRatingSummary.fromProperties(properties);
    }
    final cleanOwnerId = ownerId.trim();
    if (cleanOwnerId.isEmpty) return OwnerRatingSummary.empty;
    try {
      final snap = await firestore
          .collection(FirestoreCollections.properties)
          .where('ownerId', isEqualTo: cleanOwnerId)
          .get();
      final list = <PropertyDoc>[];
      for (final d in snap.docs) {
        try {
          list.add(PropertyDoc.fromSnapshot(d));
        } catch (_) {}
      }
      _rememberTitles(list);
      return OwnerRatingSummary.fromProperties(list);
    } catch (_) {
      return OwnerRatingSummary.empty;
    }
  }

  /// One page of tenant reviews for a property, newest first.
  ///
  /// [listingLevel] false: ratings of this exact listing (`propertyId == X`).
  /// [listingLevel] true: ratings of every room of the building/listing X
  /// (`parentPropertyId == X`). Pass the last doc of the previous page as
  /// [startAfter] to load more; a page shorter than [limit] is the last one.
  /// Needs the (propertyId|parentPropertyId, raterRole, createdAt desc)
  /// indexes in firestore.indexes.json.
  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchRatingDocsForProperty({
    required FirebaseFirestore firestore,
    required String propertyId,
    bool listingLevel = false,
    int limit = reviewsPageSize,
    DocumentSnapshot<Object?>? startAfter,
  }) async {
    final id = propertyId.trim();
    if (id.isEmpty) return const [];
    Query<Map<String, dynamic>> q = firestore
        .collection(FirestoreCollections.ratings)
        .where(listingLevel ? 'parentPropertyId' : 'propertyId', isEqualTo: id)
        // Owners' ratings of tenants carry the propertyId too: tenant reviews only.
        .where('raterRole', isEqualTo: 'tenant')
        .orderBy('createdAt', descending: true);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    final snap = await q.limit(limit).get();
    return snap.docs;
  }

  /// One page of the tenant reviews an owner received across all their
  /// properties (`ratedId == ownerId`, newest first; existing ratedId +
  /// createdAt index), each with the rated listing's title when it is known
  /// from property docs already loaded. Paginate with [startAfter] (the last
  /// returned `doc`).
  static Future<
      List<
          ({
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
            String? propertyTitle,
          })>> fetchRatingDocsForOwner({
    required FirebaseFirestore firestore,
    required String ownerId,
    int limit = reviewsPageSize,
    DocumentSnapshot<Object?>? startAfter,
  }) async {
    final cleanOwnerId = ownerId.trim();
    if (cleanOwnerId.isEmpty) return const [];
    Query<Map<String, dynamic>> q = firestore
        .collection(FirestoreCollections.ratings)
        .where('ratedId', isEqualTo: cleanOwnerId)
        .orderBy('createdAt', descending: true);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    final snap = await q.limit(limit).get();
    // Every rating with ratedId == an owner is a tenant's rating (rules: a
    // tenant rates the inquiry's owner, an owner rates the tenant, and roles
    // are permanent), so no raterRole filter is needed and pages stay exact.
    return [
      for (final d in snap.docs) (doc: d, propertyTitle: _titleFor(d.data())),
    ];
  }

  /// One page of the owner reviews a tenant received (`ratedId == tenantId`,
  /// `raterRole == 'owner'`, newest first), each with the rated listing's
  /// title when it is known from property docs already loaded. Paginate with
  /// [startAfter] (the last returned `doc`); a page shorter than [limit] is
  /// the last one. Needs the (ratedId, raterRole, createdAt desc) index in
  /// firestore.indexes.json. The summary comes from the tenant's counters
  /// ([OwnerRatingSummary.fromTenantProfile]), not from these pages.
  static Future<
      List<
          ({
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
            String? propertyTitle,
          })>> fetchRatingDocsForTenant({
    required FirebaseFirestore firestore,
    required String tenantId,
    int limit = reviewsPageSize,
    DocumentSnapshot<Object?>? startAfter,
  }) async {
    final cleanTenantId = tenantId.trim();
    if (cleanTenantId.isEmpty) return const [];
    Query<Map<String, dynamic>> q = firestore
        .collection(FirestoreCollections.ratings)
        .where('ratedId', isEqualTo: cleanTenantId)
        .where('raterRole', isEqualTo: 'owner')
        .orderBy('createdAt', descending: true);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    final snap = await q.limit(limit).get();
    return [
      for (final d in snap.docs) (doc: d, propertyTitle: _titleFor(d.data())),
    ];
  }

  static String? _titleFor(Map<String, dynamic> rating) {
    for (final key in const ['propertyId', 'parentPropertyId']) {
      final id = (rating[key] as String?)?.trim();
      if (id != null && id.isNotEmpty && _titleCache[id] != null) {
        return _titleCache[id];
      }
    }
    return null;
  }
}
