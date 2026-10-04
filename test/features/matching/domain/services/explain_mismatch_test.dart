import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/matching/domain/entities/mismatch_reason.dart';
import 'package:rentease/features/matching/domain/services/filtering_service.dart';

TenantProfileDoc _tenant(Map<String, dynamic> m) => TenantProfileDoc.fromMap('t', {
  'maxBudget': 4000,
  'maxDistanceKm': 3,
  ...m,
});

PropertyDoc _prop(Map<String, dynamic> m) =>
    PropertyDoc.fromMap('p', {'monthlyRent': 3000, ...m});

List<MismatchReason> _explain(
  Map<String, dynamic> t,
  Map<String, dynamic> p, {
  String gender = '',
  num km = 1,
}) => FilteringService.explainMismatch(
  tenantGender: gender,
  tenant: _tenant(t),
  property: _prop(p),
  distanceKm: km,
);

/// B_score from the real scoring functions, for the iff check.
bool _passes(Map<String, dynamic> t, Map<String, dynamic> p, String g, num km) {
  final tenant = _tenant(t);
  final prop = _prop(p);
  return FilteringService.computeBilateralScore(
        FilteringService.computePropertySideScore(
          tenantGender: g,
          tenant: tenant,
          property: prop,
        ),
        FilteringService.computeTenantSideScore(
          tenant: tenant,
          property: prop,
          distanceKm: km,
        ),
      ) ==
      1;
}

typedef _Case = (
  String,
  Map<String, dynamic>,
  Map<String, dynamic>,
  String,
  num,
  List<MismatchKind>,
);

void main() {
  final cases = <_Case>[
    ('compatible', {}, {}, '', 1, []),
    ('boundary budget + distance pass', {'maxBudget': 3000}, {}, '', 3, []),
    ('over budget', {'maxBudget': 2200}, {}, '', 1, [MismatchKind.overBudget]),
    (
      'tenant gender not allowed',
      {},
      {'allowedGender': 'Female only'},
      'Male',
      1,
      [MismatchKind.tenantGenderNotAllowed],
    ),
    (
      'required policy differs',
      {'requiredGender': 'Male only'},
      {'allowedGender': 'Female only'},
      'Female',
      1,
      [MismatchKind.genderPolicy],
    ),
    (
      'smoker',
      {'isSmoker': true},
      {'smokingAllowed': false},
      '',
      1,
      [MismatchKind.smoking],
    ),
    (
      'pet',
      {'hasPet': true},
      {'petsAllowed': false},
      '',
      1,
      [MismatchKind.pets],
    ),
    (
      'group too big',
      {'groupSize': 4},
      {'maxOccupants': 2},
      '',
      1,
      [MismatchKind.overCapacity],
    ),
    (
      'wifi missing',
      {'needsWifi': true},
      {'hasWifi': false},
      '',
      1,
      [MismatchKind.noWifi],
    ),
    ('wifi not needed', {'needsWifi': false}, {'hasWifi': false}, '', 1, []),
    ('too far', {}, {}, '', 4.2, [MismatchKind.tooFar]),
    (
      'several at once',
      {'maxBudget': 1000, 'needsWifi': true},
      {'hasWifi': false},
      '',
      9,
      [MismatchKind.overBudget, MismatchKind.noWifi, MismatchKind.tooFar],
    ),
  ];

  for (final (name, t, p, g, km, kinds) in cases) {
    test('explainMismatch: $name', () {
      final reasons = _explain(t, p, gender: g, km: km);
      expect(reasons.map((r) => r.kind).toList(), kinds);
      // Empty <=> B_score = 1 using the real scoring functions.
      expect(reasons.isEmpty, _passes(t, p, g, km));
    });
  }

  test('amounts and labels', () {
    final r = _explain({'maxBudget': 4000}, {'monthlyRent': 4800}, km: 4.15);
    expect(r[0], const MismatchReason(MismatchKind.overBudget, 800));
    expect(r[0].shortLabel, '₱800 over budget');
    expect(r[1].kind, MismatchKind.tooFar);
    expect(r[1].shortLabel, '1.2 km too far');
    expect(const MismatchReason(MismatchKind.noWifi).shortLabel, 'No WiFi');
  });
}
