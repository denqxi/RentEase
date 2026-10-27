import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_collections.dart';
import 'models/firestore_parse.dart';
import 'models/property_doc.dart';

/// Aggregates and hydrates property ratings directly from `ratings/{ratingId}`
/// across the app (Tenant Home, Compatible Properties, Other Listings, Search,
/// Saved Screen, Property Details, and Landlord screens).
class PropertyRatingsAggregator {
  PropertyRatingsAggregator._();

  static final Map<FirebaseFirestore, _CachedRatingsSnapshot> _cache = {};
  static final Map<FirebaseFirestore, Future<_CachedRatingsSnapshot>> _inFlight = {};
  static final Map<String, _PropertyGroupMeta> _propertyMetaCache = {};

  static const Duration _cacheTtl = Duration(seconds: 60);
  static final RegExp _dashRe = RegExp(r'^(.+?)\s+[—–-]\s+(.+)$');

  /// Clears the in-memory ratings cache (call after submitting a new rating).
  static void invalidateCache() {
    _cache.clear();
    _inFlight.clear();
  }

  /// Extracts the target `propertyId` from a `ratings` document map.
  ///
  /// Handles both explicit `propertyId` fields and legacy rating documents
  /// where `inquiryId` follows the deterministic `{tenantId}_{propertyId}` format.
  static String? extractPropertyId(
    Map<String, dynamic> data, {
    String? docId,
  }) {
    final explicit = (data['propertyId'] as String?)?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    final inqId = (data['inquiryId'] as String?)?.trim() ?? '';
    final raterId = (data['raterId'] as String?)?.trim() ?? '';

    if (raterId.isNotEmpty &&
        inqId.startsWith('${raterId}_') &&
        inqId.length > raterId.length + 1) {
      return inqId.substring(raterId.length + 1);
    }

    final firstUnderscore = inqId.indexOf('_');
    if (firstUnderscore > 0 && firstUnderscore + 1 < inqId.length) {
      return inqId.substring(firstUnderscore + 1);
    }

    if (docId != null &&
        raterId.isNotEmpty &&
        docId.startsWith('${raterId}_') &&
        docId.endsWith('_$raterId') &&
        docId.length > (raterId.length * 2) + 2) {
      return docId.substring(
        raterId.length + 1,
        docId.length - raterId.length - 1,
      );
    }

    return null;
  }

  static String _normalizeBuildingName({String? propertyName, String? title}) {
    if (propertyName != null && propertyName.trim().isNotEmpty) {
      return propertyName.trim().toLowerCase();
    }
    if (title != null && title.trim().isNotEmpty) {
      final raw = title.trim();
      final match = _dashRe.firstMatch(raw);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim().toLowerCase();
      }
      return raw.toLowerCase();
    }
    return '';
  }

  static void _recordPropertyMeta(PropertyDoc p) {
    final bName = _normalizeBuildingName(
      propertyName: p.propertyName,
      title: p.title,
    );
    final displayTitle = p.title.trim().isNotEmpty
        ? p.title.trim()
        : (p.propertyName?.trim() ?? '');
    _propertyMetaCache[p.propertyId] = _PropertyGroupMeta(
      propertyId: p.propertyId,
      parentPropertyId: p.parentPropertyId?.trim(),
      ownerId: p.ownerId.trim(),
      normalizedBuildingName: bName,
      displayTitle: displayTitle,
    );
  }

  static Future<_CachedRatingsSnapshot> _getSnapshot(
    FirebaseFirestore firestore, {
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh) {
      final existing = _cache[firestore];
      if (existing != null && now.difference(existing.fetchedAt) < _cacheTtl) {
        return existing;
      }
      final activeFuture = _inFlight[firestore];
      if (activeFuture != null) {
        return activeFuture;
      }
    }

    final future = _fetchSnapshotInternal(firestore);
    _inFlight[firestore] = future;
    try {
      final result = await future;
      _cache[firestore] = result;
      return result;
    } finally {
      if (_inFlight[firestore] == future) {
        _inFlight.remove(firestore);
      }
    }
  }

  static Future<_CachedRatingsSnapshot> _fetchSnapshotInternal(
    FirebaseFirestore firestore,
  ) async {
    final entries = <_ResolvedRatingEntry>[];
    try {
      final snap = await firestore
          .collection(FirestoreCollections.ratings)
          .where('raterRole', isEqualTo: 'tenant')
          .get();

      final missingPropIds = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final propId = extractPropertyId(data, docId: doc.id);
        if (propId != null &&
            propId.isNotEmpty &&
            !_propertyMetaCache.containsKey(propId)) {
          missingPropIds.add(propId);
        }
      }

      // Fetch metadata for any rated propertyId not yet in _propertyMetaCache
      // so we know its parentPropertyId and building name even if that room is booked.
      if (missingPropIds.isNotEmpty) {
        final idsList = missingPropIds.toList();
        for (var i = 0; i < idsList.length; i += 10) {
          final chunk = idsList.sublist(
            i,
            i + 10 > idsList.length ? idsList.length : i + 10,
          );
          try {
            final propSnap = await firestore
                .collection(FirestoreCollections.properties)
                .where(FieldPath.documentId, whereIn: chunk)
                .get();
            for (final pDoc in propSnap.docs) {
              try {
                _recordPropertyMeta(PropertyDoc.fromSnapshot(pDoc));
              } catch (_) {}
            }
          } catch (_) {}
        }
      }

      for (final doc in snap.docs) {
        final data = doc.data();
        final stars = parseNum(data['stars'], 0);
        if (stars <= 0) continue;

        final propId = extractPropertyId(data, docId: doc.id);
        final explicitParentId = (data['parentPropertyId'] as String?)?.trim();
        final meta = propId != null ? _propertyMetaCache[propId] : null;
        final parentId = (explicitParentId != null && explicitParentId.isNotEmpty)
            ? explicitParentId
            : meta?.parentPropertyId;
        final ownerId = ((data['ratedId'] as String?)?.trim().isNotEmpty ?? false)
            ? (data['ratedId'] as String).trim()
            : (meta?.ownerId ?? '');

        entries.add(
          _ResolvedRatingEntry(
            doc: doc,
            stars: stars,
            propertyId: propId,
            parentPropertyId: parentId,
            ownerId: ownerId,
            normalizedBuildingName: meta?.normalizedBuildingName ?? '',
          ),
        );
      }
    } catch (_) {
      // Guest users or restricted environments without read access to `ratings`
      // fall back cleanly to the fields already stored on PropertyDoc.
    }

    return _CachedRatingsSnapshot(
      entries: entries,
      fetchedAt: DateTime.now(),
    );
  }

  /// Hydrates a single [PropertyDoc] with its aggregated ratings from `ratings`.
  static Future<PropertyDoc> hydrateProperty(
    FirebaseFirestore firestore,
    PropertyDoc property, {
    bool forceRefresh = false,
  }) async {
    final list = await hydrateProperties(
      firestore,
      [property],
      forceRefresh: forceRefresh,
    );
    return list.first;
  }

  /// Hydrates a list of [PropertyDoc]s with aggregated ratings from `ratings`.
  static Future<List<PropertyDoc>> hydrateProperties(
    FirebaseFirestore firestore,
    List<PropertyDoc> properties, {
    bool forceRefresh = false,
  }) async {
    if (properties.isEmpty) return properties;

    for (final p in properties) {
      _recordPropertyMeta(p);
    }

    final snapshot = await _getSnapshot(firestore, forceRefresh: forceRefresh);
    if (snapshot.entries.isEmpty) return properties;

    return [
      for (final p in properties) _applyRatingsToProperty(p, snapshot.entries),
    ];
  }

  /// Returns `(avgRating, totalCount)` for a property/building from `ratings`,
  /// or `null` if there are no ratings for it.
  static Future<(double avg, int count)?> getRatingForProperty({
    required FirebaseFirestore firestore,
    required String propertyId,
    String? parentPropertyId,
    String? ownerId,
    String? propertyName,
    String? title,
    bool forceRefresh = false,
  }) async {
    if (propertyId.trim().isEmpty) return null;
    final snapshot = await _getSnapshot(firestore, forceRefresh: forceRefresh);
    if (snapshot.entries.isEmpty) return null;

    final matched = _matchEntriesForProperty(
      entries: snapshot.entries,
      propertyId: propertyId,
      parentPropertyId: parentPropertyId,
      ownerId: ownerId,
      propertyName: propertyName,
      title: title,
    );
    if (matched.isEmpty) return null;

    num sum = 0;
    for (final e in matched) {
      sum += e.stars;
    }
    return ((sum / matched.length).toDouble(), matched.length);
  }

  static PropertyDoc _applyRatingsToProperty(
    PropertyDoc p,
    List<_ResolvedRatingEntry> entries,
  ) {
    final matched = _matchEntriesForProperty(
      entries: entries,
      propertyId: p.propertyId,
      parentPropertyId: p.parentPropertyId,
      ownerId: p.ownerId,
      propertyName: p.propertyName,
      title: p.title,
    );

    if (matched.isEmpty) return p;

    num sum = 0;
    for (final e in matched) {
      sum += e.stars;
    }
    final count = matched.length;
    final avg = (sum / count).toDouble();

    return p.withRatings(
      avgRating: avg,
      totalRatings: count,
      ratingSum: sum,
    );
  }

  static List<_ResolvedRatingEntry> _matchEntriesForProperty({
    required List<_ResolvedRatingEntry> entries,
    required String propertyId,
    String? parentPropertyId,
    String? ownerId,
    String? propertyName,
    String? title,
    Set<String>? extraTargetIds,
    String? inquiryId,
  }) {
    final propMeta = _propertyMetaCache[propertyId.trim()];
    final effectiveParentId =
        (parentPropertyId != null && parentPropertyId.trim().isNotEmpty)
            ? parentPropertyId.trim()
            : propMeta?.parentPropertyId;
    final effectiveOwnerId = (ownerId != null && ownerId.trim().isNotEmpty)
        ? ownerId.trim()
        : (propMeta?.ownerId ?? '');
    final normBuilding = _normalizeBuildingName(
      propertyName: propertyName,
      title: title,
    );
    final effectiveBuilding = normBuilding.isNotEmpty
        ? normBuilding
        : (propMeta?.normalizedBuildingName ?? '');

    final targetIds = <String>{
      if (propertyId.trim().isNotEmpty) propertyId.trim(),
      if (effectiveParentId != null && effectiveParentId.isNotEmpty)
        effectiveParentId,
      ...?extraTargetIds,
    };

    final byId = <String, _ResolvedRatingEntry>{};
    for (final e in entries) {
      final inq = (e.doc.data()['inquiryId'] as String?)?.trim() ?? '';
      final entryMeta =
          e.propertyId != null ? _propertyMetaCache[e.propertyId!] : null;
      final entryParent = e.parentPropertyId ?? entryMeta?.parentPropertyId;
      final entryBuilding = e.normalizedBuildingName.isNotEmpty
          ? e.normalizedBuildingName
          : (entryMeta?.normalizedBuildingName ?? '');
      final entryOwner =
          e.ownerId.isNotEmpty ? e.ownerId : (entryMeta?.ownerId ?? '');

      if (inquiryId != null && inquiryId.isNotEmpty && inq == inquiryId) {
        byId[e.doc.id] = e;
        continue;
      }
      if (e.propertyId != null && targetIds.contains(e.propertyId)) {
        byId[e.doc.id] = e;
        continue;
      }
      if (entryParent != null &&
          entryParent.isNotEmpty &&
          targetIds.contains(entryParent)) {
        byId[e.doc.id] = e;
        continue;
      }
      if (targetIds.any((id) => inq.endsWith('_$id') || inq == id)) {
        byId[e.doc.id] = e;
        continue;
      }
      if (effectiveBuilding.isNotEmpty &&
          effectiveOwnerId.isNotEmpty &&
          entryOwner == effectiveOwnerId &&
          entryBuilding == effectiveBuilding) {
        byId[e.doc.id] = e;
        continue;
      }
      // If the rating's original property doc no longer exists in Firestore
      // (or had no propertyId), match by ownerId so orphaned ratings still show.
      final hasKnownExistingProperty =
          e.propertyId != null && _propertyMetaCache.containsKey(e.propertyId!);
      if (!hasKnownExistingProperty &&
          effectiveOwnerId.isNotEmpty &&
          entryOwner == effectiveOwnerId) {
        byId[e.doc.id] = e;
        continue;
      }
    }

    final result = byId.values.toList()
      ..sort((a, b) {
        final tA =
            parseTimestamp(a.doc.data()['createdAt'])?.millisecondsSinceEpoch ??
                0;
        final tB =
            parseTimestamp(b.doc.data()['createdAt'])?.millisecondsSinceEpoch ??
                0;
        return tB.compareTo(tA);
      });
    return result;
  }

  /// Returns all matching tenant rating documents for a property/building,
  /// sorted newest-first. Used by `PropertyDetailScreen` and `PropertyReviewsScreen`.
  static Future<List<DocumentSnapshot<Map<String, dynamic>>>>
      fetchRatingDocsForProperty({
    required FirebaseFirestore firestore,
    required String propertyId,
    String? parentPropertyId,
    String? ownerId,
    String? propertyName,
    String? title,
    Set<String>? extraTargetIds,
    String? inquiryId,
    bool forceRefresh = false,
  }) async {
    final snapshot = await _getSnapshot(firestore, forceRefresh: forceRefresh);
    final matched = _matchEntriesForProperty(
      entries: snapshot.entries,
      propertyId: propertyId,
      parentPropertyId: parentPropertyId,
      ownerId: ownerId,
      propertyName: propertyName,
      title: title,
      extraTargetIds: extraTargetIds,
      inquiryId: inquiryId,
    );
    return [for (final m in matched) m.doc];
  }

  /// Returns `(avgRating, totalCount)` rolled up across all properties owned by [ownerId],
  /// or `null` if the owner's properties have no tenant ratings yet.
  static Future<(double avg, int count)?> getOwnerRollupRating({
    required FirebaseFirestore firestore,
    required String ownerId,
    bool forceRefresh = false,
  }) async {
    final cleanOwnerId = ownerId.trim();
    if (cleanOwnerId.isEmpty) return null;

    final snapshot = await _getSnapshot(firestore, forceRefresh: forceRefresh);
    if (snapshot.entries.isEmpty) return null;

    final matched = _matchEntriesForOwner(
      entries: snapshot.entries,
      ownerId: cleanOwnerId,
    );
    if (matched.isEmpty) return null;

    num sum = 0;
    for (final e in matched) {
      sum += e.stars;
    }
    return ((sum / matched.length).toDouble(), matched.length);
  }

  /// Returns all tenant property rating documents rolled up for [ownerId],
  /// sorted newest-first, paired with the resolved `propertyTitle` of each rated property/room.
  static Future<
      List<
          ({
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
            String? propertyTitle,
          })>> fetchRatingDocsForOwner({
    required FirebaseFirestore firestore,
    required String ownerId,
    bool forceRefresh = false,
  }) async {
    final cleanOwnerId = ownerId.trim();
    if (cleanOwnerId.isEmpty) return const [];

    final snapshot = await _getSnapshot(firestore, forceRefresh: forceRefresh);
    if (snapshot.entries.isEmpty) return const [];

    final matched = _matchEntriesForOwner(
      entries: snapshot.entries,
      ownerId: cleanOwnerId,
    );

    return [
      for (final m in matched)
        (
          doc: m.doc,
          propertyTitle: _resolveTitleForEntry(m),
        ),
    ];
  }

  static String? _resolveTitleForEntry(_ResolvedRatingEntry e) {
    if (e.propertyId != null) {
      final meta = _propertyMetaCache[e.propertyId!];
      if (meta != null && meta.displayTitle.isNotEmpty) {
        return meta.displayTitle;
      }
    }
    if (e.parentPropertyId != null) {
      final parentMeta = _propertyMetaCache[e.parentPropertyId!];
      if (parentMeta != null && parentMeta.displayTitle.isNotEmpty) {
        return parentMeta.displayTitle;
      }
    }
    return null;
  }

  static List<_ResolvedRatingEntry> _matchEntriesForOwner({
    required List<_ResolvedRatingEntry> entries,
    required String ownerId,
  }) {
    final byId = <String, _ResolvedRatingEntry>{};
    for (final e in entries) {
      final entryMeta =
          e.propertyId != null ? _propertyMetaCache[e.propertyId!] : null;
      final parentMeta = e.parentPropertyId != null
          ? _propertyMetaCache[e.parentPropertyId!]
          : null;
      final resolvedOwner = e.ownerId.isNotEmpty
          ? e.ownerId
          : (entryMeta?.ownerId.isNotEmpty == true
              ? entryMeta!.ownerId
              : (parentMeta?.ownerId ?? ''));

      if (resolvedOwner == ownerId) {
        byId[e.doc.id] = e;
      }
    }

    final result = byId.values.toList()
      ..sort((a, b) {
        final tA =
            parseTimestamp(a.doc.data()['createdAt'])?.millisecondsSinceEpoch ??
                0;
        final tB =
            parseTimestamp(b.doc.data()['createdAt'])?.millisecondsSinceEpoch ??
                0;
        return tB.compareTo(tA);
      });
    return result;
  }
}

class _PropertyGroupMeta {
  const _PropertyGroupMeta({
    required this.propertyId,
    this.parentPropertyId,
    required this.ownerId,
    required this.normalizedBuildingName,
    this.displayTitle = '',
  });

  final String propertyId;
  final String? parentPropertyId;
  final String ownerId;
  final String normalizedBuildingName;
  final String displayTitle;
}

class _ResolvedRatingEntry {
  const _ResolvedRatingEntry({
    required this.doc,
    required this.stars,
    this.propertyId,
    this.parentPropertyId,
    required this.ownerId,
    required this.normalizedBuildingName,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final num stars;
  final String? propertyId;
  final String? parentPropertyId;
  final String ownerId;
  final String normalizedBuildingName;
}

class _CachedRatingsSnapshot {
  const _CachedRatingsSnapshot({
    required this.entries,
    required this.fetchedAt,
  });

  final List<_ResolvedRatingEntry> entries;
  final DateTime fetchedAt;
}
