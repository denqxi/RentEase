import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';

const _pin = GeoPoint(7.07, 125.6);

TenantProfileDoc _profile() => const TenantProfileDoc(
  userId: 't1',
  maxBudget: 4500,
  requiredGender: 'Mixed / Any',
  needsWifi: true,
  maxDistanceKm: 3,
  poiLatLng: _pin,
  poiLabel: 'USEP',
  poiType: 'School',
  isSmoker: false,
  hasPet: false,
  groupSize: 1,
  wRent: 0.5,
  wDistance: 0.3,
  wAmenities: 0.2,
);

void main() {
  group('TenantProfileDoc (public, owner-readable)', () {
    test('toMap never contains the map pin or the weights', () {
      final map = _profile().toMap();
      for (final key in TenantPrivatePrefsDoc.legacyProfileKeys) {
        expect(map.containsKey(key), isFalse, reason: key);
      }
      expect(map['maxBudget'], 4500);
      expect(map['maxDistanceKm'], 3);
    });

    test('toPrefs carries exactly the private half', () {
      final prefs = _profile().toPrefs().toMap();
      expect(prefs['poiLatLng'], _pin);
      expect(prefs['poiLabel'], 'USEP');
      expect(prefs['poiType'], 'School');
      expect(prefs['wRent'], 0.5);
      expect(prefs.containsKey('maxBudget'), isFalse);
    });

    test('withPrefs overlays private values and keeps public ones', () {
      final merged = TenantProfileDoc.fromMap('t1', {'maxBudget': 4000}).withPrefs(
        const TenantPrivatePrefsDoc(
          poiLatLng: _pin,
          poiLabel: 'ADDU',
          wRent: 0.6,
          wDistance: 0.2,
          wAmenities: 0.2,
        ),
      );
      expect(merged.maxBudget, 4000);
      expect(merged.poiLatLng, _pin);
      expect(merged.poiLabel, 'ADDU');
      expect(merged.wRent, 0.6);
    });

    test('withPrefs(null) or a partial prefs doc keeps legacy fallbacks', () {
      final legacy = TenantProfileDoc.fromMap('t1', {
        'poiLatLng': _pin,
        'wRent': 0.4,
        'wDistance': 0.4,
        'wAmenities': 0.2,
      });
      expect(legacy.withPrefs(null).poiLatLng, _pin);
      final partial = legacy.withPrefs(const TenantPrivatePrefsDoc(wRent: 0.5));
      expect(partial.poiLatLng, _pin);
      expect(partial.wRent, 0.5);
      expect(partial.wDistance, 0.4);
    });

    test('an owner-side read has defaults, not a real pin', () {
      final ownerView = TenantProfileDoc.fromMap('t1', {'maxBudget': 4000});
      expect(ownerView.poiLatLng, const GeoPoint(0, 0));
      expect(ownerView.wRent, 0.35);
    });
  });

  group('legacy self-migration plan', () {
    test('copies legacy values and removes every legacy key', () {
      final profile = {
        'maxBudget': 4500,
        'poiLatLng': _pin,
        'poiLabel': 'USEP',
        'wRent': 0.35,
      };
      expect(TenantPrivatePrefsDoc.hasLegacyFields(profile), isTrue);
      final plan = TenantPrivatePrefsDoc.legacyMigrationPlan(profile, const {});
      expect(plan.copy, {'poiLatLng': _pin, 'poiLabel': 'USEP', 'wRent': 0.35});
      expect(plan.remove, ['poiLatLng', 'poiLabel', 'wRent']);
    });

    test('an existing prefs value is never overwritten', () {
      final plan = TenantPrivatePrefsDoc.legacyMigrationPlan(
        {'wRent': 0.35, 'wDistance': 0.35},
        {'wRent': 0.6},
      );
      expect(plan.copy, {'wDistance': 0.35});
      expect(plan.remove, ['wRent', 'wDistance']);
    });

    test('is idempotent: a clean profile yields an empty plan', () {
      final clean = _profile().toMap();
      expect(TenantPrivatePrefsDoc.hasLegacyFields(clean), isFalse);
      final plan = TenantPrivatePrefsDoc.legacyMigrationPlan(clean, const {});
      expect(plan.copy, isEmpty);
      expect(plan.remove, isEmpty);
    });

    test('a null legacy value is removed but not copied', () {
      final plan = TenantPrivatePrefsDoc.legacyMigrationPlan(
        {'poiType': null},
        const {},
      );
      expect(plan.copy, isEmpty);
      expect(plan.remove, ['poiType']);
    });
  });
}
