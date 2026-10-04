// Parity guard: firestore-tests/parity_cases.json is asserted here against the
// Dart FilteringService (non-distance parts) and, in firestore-tests/
// rules.test.js, against firestore.rules via the emulator. If one side
// changes, the other test fails.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/matching/domain/services/filtering_service.dart';

void main() {
  final cases =
      (jsonDecode(File('firestore-tests/parity_cases.json').readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>();

  for (final c in cases) {
    test('parity: ${c['name']}', () {
      final tenant = TenantProfileDoc.fromMap(
        'tenantA',
        (c['tp'] as Map).cast<String, dynamic>(),
      );
      final property = PropertyDoc.fromMap(
        'prop',
        (c['prop'] as Map).cast<String, dynamic>(),
      );
      final p = FilteringService.computePropertySideScore(
        tenantGender: c['gender'] as String,
        tenant: tenant,
        property: property,
      );
      // distanceKm 0 -> LocationMatch always passes: non-distance parts only.
      final t = FilteringService.computeTenantSideScore(
        tenant: tenant,
        property: property,
        distanceKm: 0,
      );
      expect(FilteringService.computeBilateralScore(p, t) == 1, c['ok']);
      // explainMismatch is empty exactly when B_score = 1.
      final reasons = FilteringService.explainMismatch(
        tenantGender: c['gender'] as String,
        tenant: tenant,
        property: property,
        distanceKm: 0,
      );
      expect(reasons.isEmpty, c['ok']);
    });
  }
}
