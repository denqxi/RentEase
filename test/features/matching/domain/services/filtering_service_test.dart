// Test oracle from SPRINTPLAN.md section 2.4 — if this doesn't reproduce
// the documented numbers, FilteringService must not be considered correct.
// Gender strings are translated to the app's real constants ('Female only',
// 'Mixed / Any' — see property_rules_screen.dart /
// hard_constraints_screen.dart) rather than SPRINTPLAN's illustrative
// "Female Only" / "All" casing; the expected B_scores are unchanged.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/matching/domain/services/filtering_service.dart';

TenantProfileDoc _tenant({
  required num maxBudget,
  required String requiredGender,
  required bool needsWifi,
  required num maxDistanceKm,
  required bool isSmoker,
  required bool hasPet,
  required num groupSize,
}) {
  return TenantProfileDoc(
    userId: 't1',
    maxBudget: maxBudget,
    requiredGender: requiredGender,
    needsWifi: needsWifi,
    maxDistanceKm: maxDistanceKm,
    poiLatLng: const GeoPoint(0, 0),
    poiLabel: 'Test POI',
    isSmoker: isSmoker,
    hasPet: hasPet,
    groupSize: groupSize,
    wRent: 0.35,
    wDistance: 0.35,
    wAmenities: 0.30,
  );
}

PropertyDoc _property({
  required String allowedGender,
  required bool smokingAllowed,
  required bool petsAllowed,
  required num maxOccupants,
  required num monthlyRent,
  required bool hasWifi,
}) {
  return PropertyDoc(
    propertyId: 'p1',
    ownerId: 'o1',
    title: 'Test Property',
    address: 'Test address',
    location: const GeoPoint(0, 0),
    geoHash: '',
    photos: const [],
    monthlyRent: monthlyRent,
    depositAmount: 0,
    advanceMonths: 0,
    isAvailable: true,
    vacancyStatus: 'available',
    isVerified: true,
    allowedGender: allowedGender,
    smokingAllowed: smokingAllowed,
    petsAllowed: petsAllowed,
    maxOccupants: maxOccupants,
    hasWifi: hasWifi,
    amenityList: const [],
  );
}

void main() {
  // Tenant: Female, non-smoker, has pet, groupSize=1, maxBudget=₱4500,
  // requiredGender=Female only, needsWifi=true, maxDistanceKm=2.0
  final tenant = _tenant(
    maxBudget: 4500,
    requiredGender: 'Female only',
    needsWifi: true,
    maxDistanceKm: 2.0,
    isSmoker: false,
    hasPet: true,
    groupSize: 1,
  );
  const tenantGender = 'Female';

  num bScoreFor(PropertyDoc property, num distanceKm) {
    final pScore = FilteringService.computePropertySideScore(
      tenantGender: tenantGender,
      tenant: tenant,
      property: property,
    );
    final tScore = FilteringService.computeTenantSideScore(
      tenant: tenant,
      property: property,
      distanceKm: distanceKm,
    );
    return FilteringService.computeBilateralScore(pScore, tScore);
  }

  test('BH1 is rejected — fails pet policy (tenant has a pet, property does not allow pets)', () {
    final bh1 = _property(
      allowedGender: 'Female only',
      smokingAllowed: false,
      petsAllowed: false,
      maxOccupants: 2,
      monthlyRent: 4000,
      hasWifi: true,
    );
    expect(bScoreFor(bh1, 1.5), 0);
  });

  test('BH2 is eligible', () {
    final bh2 = _property(
      allowedGender: 'Female only',
      smokingAllowed: false,
      petsAllowed: true,
      maxOccupants: 2,
      monthlyRent: 4500,
      hasWifi: true,
    );
    expect(bScoreFor(bh2, 0.8), 1);
  });

  test('BH3 is rejected — fails WiFi requirement (tenant needs WiFi, property has none)', () {
    final bh3 = _property(
      allowedGender: 'Mixed / Any',
      smokingAllowed: false,
      petsAllowed: true,
      maxOccupants: 1,
      monthlyRent: 3500,
      hasWifi: false,
    );
    expect(bScoreFor(bh3, 2.0), 0);
  });

  test('BH4 is eligible', () {
    final bh4 = _property(
      allowedGender: 'Female only',
      smokingAllowed: false,
      petsAllowed: true,
      maxOccupants: 1,
      monthlyRent: 3800,
      hasWifi: true,
    );
    expect(bScoreFor(bh4, 1.0), 1);
  });

  test('BH5 is eligible', () {
    final bh5 = _property(
      allowedGender: 'Mixed / Any',
      smokingAllowed: false,
      petsAllowed: true,
      maxOccupants: 2,
      monthlyRent: 4200,
      hasWifi: true,
    );
    expect(bScoreFor(bh5, 1.8), 1);
  });

  group('computeBilateralScore', () {
    test('1 only when both sides are 1', () {
      expect(FilteringService.computeBilateralScore(1, 1), 1);
      expect(FilteringService.computeBilateralScore(0, 1), 0);
      expect(FilteringService.computeBilateralScore(1, 0), 0);
      expect(FilteringService.computeBilateralScore(0, 0), 0);
    });
  });

  group('computeTenantSideScore — needsWifi governs, not hardcoded', () {
    test('a tenant who does not need WiFi is not rejected by a WiFi-less property', () {
      final noWifiNeeded = _tenant(
        maxBudget: 4500,
        requiredGender: 'Mixed / Any',
        needsWifi: false,
        maxDistanceKm: 5,
        isSmoker: false,
        hasPet: false,
        groupSize: 1,
      );
      final property = _property(
        allowedGender: 'Mixed / Any',
        smokingAllowed: true,
        petsAllowed: true,
        maxOccupants: 2,
        monthlyRent: 3000,
        hasWifi: false,
      );
      expect(
        FilteringService.computeTenantSideScore(
          tenant: noWifiNeeded,
          property: property,
          distanceKm: 1.0,
        ),
        1,
      );
    });
  });
}
