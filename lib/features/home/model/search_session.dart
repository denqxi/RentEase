import '../../../core/firestore/models/tenant_profile_doc.dart';
import '../../matching/domain/entities/mismatch_reason.dart';

/// Search's session filter (CLAUDE.md "Session filters"): a temporary,
/// local-only override replicating the tenant onboarding deciding factors for
/// exploring compatible listings. Never written to Firestore (rule 3) and never
/// mutates cached match scores.
class SearchSession {
  const SearchSession({
    required this.maxBudget,
    required this.maxDistanceKm,
    this.roomType = 'Either',
    this.propertyTypes = const {},
    this.amenities = const {},
    this.groupSize = 1,
    this.requireSmokingAllowed = false,
    this.requirePetsAllowed = false,
    this.poiType,
    this.poiLabel,
  });

  final num maxBudget;
  final num maxDistanceKm;
  final String roomType; // 'Either', 'Solo', 'Shared'
  final Set<String> propertyTypes;
  final Set<String> amenities;
  final int groupSize;
  final bool requireSmokingAllowed;
  final bool requirePetsAllowed;
  final String? poiType;
  final String? poiLabel;

  bool get hasActiveOverrides =>
      roomType != 'Either' ||
      propertyTypes.isNotEmpty ||
      amenities.isNotEmpty ||
      groupSize > 1 ||
      requireSmokingAllowed ||
      requirePetsAllowed ||
      poiType != null ||
      poiLabel != null;

  SearchSession copyWith({
    num? maxBudget,
    num? maxDistanceKm,
    String? roomType,
    Set<String>? propertyTypes,
    Set<String>? amenities,
    int? groupSize,
    bool? requireSmokingAllowed,
    bool? requirePetsAllowed,
    String? poiType,
    String? poiLabel,
  }) {
    return SearchSession(
      maxBudget: maxBudget ?? this.maxBudget,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      roomType: roomType ?? this.roomType,
      propertyTypes: propertyTypes ?? this.propertyTypes,
      amenities: amenities ?? this.amenities,
      groupSize: groupSize ?? this.groupSize,
      requireSmokingAllowed:
          requireSmokingAllowed ?? this.requireSmokingAllowed,
      requirePetsAllowed: requirePetsAllowed ?? this.requirePetsAllowed,
      poiType: poiType ?? this.poiType,
      poiLabel: poiLabel ?? this.poiLabel,
    );
  }

  bool _matchesRoomType(Map<String, dynamic> p) {
    if (roomType == 'Either') return true;
    final isSolo = roomType.toLowerCase() == 'solo';
    final title = (p['title'] as String? ?? '').toLowerCase();
    final roomName = (p['roomName'] as String? ?? '').toLowerCase();
    final maxOcc = (p['maxOccupants'] as num?) ?? 1;
    if (isSolo) {
      return maxOcc <= 1 ||
          (!title.contains('bedspace') &&
              !title.contains('shared') &&
              !roomName.contains('bedspace') &&
              !roomName.contains('shared'));
    } else {
      return maxOcc > 1 ||
          title.contains('bedspace') ||
          title.contains('shared') ||
          roomName.contains('bedspace') ||
          roomName.contains('shared');
    }
  }

  bool _matchesPropertyType(Map<String, dynamic> p) {
    if (propertyTypes.isEmpty) return true;
    final rawType = (p['propertyType'] as String?)?.trim();
    final pType = (rawType != null && rawType.isNotEmpty ? rawType : 'Boarding House').toLowerCase();
    final title = (p['title'] as String? ?? '').toLowerCase();
    return propertyTypes.any((t) {
      final target = t.toLowerCase();
      if (pType.contains(target) || title.contains(target)) return true;
      if (target.contains('dorm') && (pType.contains('dorm') || title.contains('dorm'))) return true;
      if (target.contains('board') && (pType.contains('board') || title.contains('board'))) return true;
      return false;
    });
  }

  bool _matchesAmenities(Map<String, dynamic> p) {
    if (amenities.isEmpty) return true;
    final propAmenities = ((p['amenities'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toSet()) ??
        ((p['amenityList'] as List?)
            ?.map((e) => e.toString().toLowerCase())
            .toSet()) ??
        <String>{};
    final hasWifi =
        p['hasWifi'] == true || propAmenities.any((a) => a.contains('wifi'));
    return amenities.every((a) {
      final target = a.toLowerCase();
      if (target == 'wifi' && hasWifi) return true;
      return propAmenities.any((pa) => pa.contains(target));
    });
  }

  int? _occupancyExcess(Map<String, dynamic> p) {
    final maxOcc = (p['maxOccupants'] as num?) ?? 1;
    if (groupSize > maxOcc) {
      return (groupSize - maxOcc).toInt();
    }
    return null;
  }

  bool _smokingFails(Map<String, dynamic> p) {
    return requireSmokingAllowed && p['smokingAllowed'] != true;
  }

  bool _petsFails(Map<String, dynamic> p) {
    return requirePetsAllowed && p['petsAllowed'] != true;
  }

  int _budgetExcess(Map<String, dynamic> p) {
    final rent = (p['monthlyRent'] as num?) ?? 0;
    return rent > maxBudget ? (rent - maxBudget).round() : 0;
  }

  double _distanceExcess(Map<String, dynamic> p) {
    final distance = (p['distance'] as num?) ?? 0;
    return distance > maxDistanceKm
        ? ((distance - maxDistanceKm) * 10).round() / 10
        : 0;
  }

  /// Copies of [results] with `isOutsidePreference`, `budgetExcess` and
  /// `distanceExcess` set against this session. Inputs are not mutated.
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> results) {
    var list = results;

    // Room arrangement filter ('Solo' vs 'Shared')
    if (roomType != 'Either') {
      list = list.where(_matchesRoomType).toList();
    }

    // Property category filter
    if (propertyTypes.isNotEmpty) {
      list = list.where(_matchesPropertyType).toList();
    }

    // Amenities filter
    if (amenities.isNotEmpty) {
      list = list.where(_matchesAmenities).toList();
    }

    // Group size / occupancy filter
    if (groupSize > 1) {
      list = list.where((p) => _occupancyExcess(p) == null).toList();
    }

    // Smoking allowed filter
    if (requireSmokingAllowed) {
      list = list.where((p) => !_smokingFails(p)).toList();
    }

    // Pets allowed filter
    if (requirePetsAllowed) {
      list = list.where((p) => !_petsFails(p)).toList();
    }

    return [
      for (final p in list) _flag(p),
    ];
  }

  /// Evaluates both [matching] results and [nonMatches] against this session.
  ///
  /// - Promotes non-matches that now satisfy all session criteria into [matches]
  ///   (clearing mismatch reasons and setting `isNonMatch: false`).
  /// - Updates remaining non-matches with recalculated reasons reflecting
  ///   this session's criteria.
  /// - Flags matched listings exceeding budget or distance as `isOutsidePreference: true`.
  /// - Moves matched listings failing explicit criteria (e.g. group size, smoking, pets)
  ///   into [others] with appropriate mismatch reasons.
  ///
  /// Neither input list nor its maps are mutated.
  ({
    List<Map<String, dynamic>> matches,
    List<Map<String, dynamic>> others,
  }) evaluate({
    required List<Map<String, dynamic>> matching,
    required List<Map<String, dynamic>> nonMatches,
    TenantProfileDoc? profile,
  }) {
    final evaluatedMatches = <Map<String, dynamic>>[];
    final evaluatedOthers = <Map<String, dynamic>>[];

    // 1. Process matching listings
    for (final p in matching) {
      final roomTypeFail = !_matchesRoomType(p);
      final propTypeFail = !_matchesPropertyType(p);
      final amenitiesFail = !_matchesAmenities(p);
      final occExcess = _occupancyExcess(p);
      final smokingFail = _smokingFails(p);
      final petsFail = _petsFails(p);

      if (roomTypeFail ||
          propTypeFail ||
          amenitiesFail ||
          occExcess != null ||
          smokingFail ||
          petsFail) {
        final reasons = <MismatchReason>[
          if (occExcess != null)
            MismatchReason(MismatchKind.overCapacity, occExcess),
          if (smokingFail) const MismatchReason(MismatchKind.smoking),
          if (petsFail) const MismatchReason(MismatchKind.pets),
        ];
        evaluatedOthers.add({
          ...p,
          'isNonMatch': true,
          'isFilterMatch': false,
          'mismatchReasons': reasons,
          'bScore': 0,
        });
      } else {
        evaluatedMatches.add({
          ..._flag(p),
          'isFilterMatch': false,
        });
      }
    }

    // 2. Process non-matching listings
    for (final p in nonMatches) {
      final rawReasons =
          (p['mismatchReasons'] as List?)?.cast<MismatchReason>() ??
              const <MismatchReason>[];

      final newReasons = <MismatchReason>[];

      // Keep immutable gender policy reasons from original mismatch
      for (final r in rawReasons) {
        if (r.kind == MismatchKind.genderPolicy ||
            r.kind == MismatchKind.tenantGenderNotAllowed) {
          newReasons.add(r);
        }
      }

      // Check WiFi
      final hasWifi = p['hasWifi'] == true ||
          ((p['amenities'] as List?) ?? (p['amenityList'] as List?))
                  ?.any((e) => e.toString().toLowerCase().contains('wifi')) ==
              true;
      final needsWifi = (profile?.needsWifi == true) ||
          amenities.any((a) => a.toLowerCase() == 'wifi');
      if (needsWifi && !hasWifi) {
        newReasons.add(const MismatchReason(MismatchKind.noWifi));
      }

      // Check Occupancy
      final occExcess = _occupancyExcess(p);
      if (occExcess != null) {
        newReasons.add(MismatchReason(MismatchKind.overCapacity, occExcess));
      }

      // Check Smoking
      if (_smokingFails(p)) {
        newReasons.add(const MismatchReason(MismatchKind.smoking));
      }

      // Check Pets
      if (_petsFails(p)) {
        newReasons.add(const MismatchReason(MismatchKind.pets));
      }

      // Check Budget & Distance
      final bExcess = _budgetExcess(p);
      if (bExcess > 0) {
        newReasons.add(MismatchReason(MismatchKind.overBudget, bExcess));
      }

      final dExcess = _distanceExcess(p);
      if (dExcess > 0) {
        newReasons.add(MismatchReason(MismatchKind.tooFar, dExcess));
      }

      final roomTypeOk = _matchesRoomType(p);
      final propTypeOk = _matchesPropertyType(p);
      final amenitiesOk = _matchesAmenities(p);

      if (newReasons.isEmpty && roomTypeOk && propTypeOk && amenitiesOk) {
        // Satisfies all session criteria!
        // Promoted to matches as a Temporary Filter Match.
        // bScore stays 0 so bilateral check & Firestore security rules disallow direct inquiry.
        evaluatedMatches.add({
          ...p,
          'isNonMatch': false,
          'isFilterMatch': true,
          'mismatchReasons': const <MismatchReason>[],
          'bScore': 0,
          'isOutsidePreference': false,
          'budgetExcess': 0,
          'distanceExcess': 0,
        });
      } else {
        // Retained in "Other listings" — never silently deleted!
        evaluatedOthers.add({
          ...p,
          'isNonMatch': true,
          'isFilterMatch': false,
          'mismatchReasons': newReasons,
          'bScore': 0,
          'budgetExcess': bExcess,
          'distanceExcess': dExcess,
        });
      }
    }

    return (matches: evaluatedMatches, others: evaluatedOthers);
  }

  Map<String, dynamic> _flag(Map<String, dynamic> p) {
    final bExcess = _budgetExcess(p);
    final dExcess = _distanceExcess(p);
    return {
      ...p,
      'isOutsidePreference': bExcess > 0 || dExcess > 0,
      'budgetExcess': bExcess,
      'distanceExcess': dExcess,
    };
  }
}

/// Case-insensitive match of [query] against a listing's title or address.
bool matchesSearchQuery(Map<String, dynamic> p, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final title = (p['title'] as String? ?? '').toLowerCase();
  final address = (p['address'] as String? ?? '').toLowerCase();
  return title.contains(q) || address.contains(q);
}
