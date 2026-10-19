import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/features/home/model/search_session.dart';
import 'package:rentease/features/matching/domain/entities/mismatch_reason.dart';

Map<String, dynamic> _listing(
  String id, {
  num rent = 4000,
  num distance = 2.0,
  String title = 'Sunshine Boarding House',
  String address = 'Matina, Davao City',
}) => {
  'propertyId': id,
  'title': title,
  'address': address,
  'monthlyRent': rent,
  'distance': distance,
  'isOutsidePreference': false,
};

void main() {
  group('SearchSession.apply', () {
    const session = SearchSession(maxBudget: 4500, maxDistanceKm: 3);

    test('flags listings over the session budget or distance, with the excess', () {
      final result = session.apply([
        _listing('within', rent: 4500, distance: 3),
        _listing('pricey', rent: 5000, distance: 1),
        _listing('far', rent: 4000, distance: 4.25),
      ]);

      expect(result[0]['isOutsidePreference'], isFalse);
      expect(result[0]['budgetExcess'], 0);
      expect(result[0]['distanceExcess'], 0);

      expect(result[1]['isOutsidePreference'], isTrue);
      expect(result[1]['budgetExcess'], 500);

      expect(result[2]['isOutsidePreference'], isTrue);
      expect(result[2]['distanceExcess'], closeTo(1.3, 1e-9));
    });

    test('never removes or re-orders listings (TOPSIS order is kept)', () {
      final input = [
        _listing('a', rent: 9000),
        _listing('b'),
        _listing('c', distance: 9),
      ];
      final ids = session.apply(input).map((p) => p['propertyId']).toList();
      expect(ids, ['a', 'b', 'c']);
    });

    test('does not mutate the cached results', () {
      final original = _listing('a', rent: 9000);
      session.apply([original]);
      expect(original['isOutsidePreference'], isFalse);
      expect(original.containsKey('budgetExcess'), isFalse);
    });
  });

  group('SearchSession.evaluate', () {
    const session = SearchSession(
      maxBudget: 5200,
      maxDistanceKm: 5,
      groupSize: 1,
    );

    test('promotes non-matches that satisfy the session filter to matches', () {
      final nonMatch = {
        'propertyId': 'p1',
        'monthlyRent': 3500,
        'distance': 2.0,
        'maxOccupants': 1,
        'isNonMatch': true,
        'bScore': 0,
        'mismatchReasons': [
          const MismatchReason(MismatchKind.overCapacity, 1),
        ],
      };

      final result = session.evaluate(
        matching: [],
        nonMatches: [nonMatch],
      );

      expect(result.matches.length, 1);
      expect(result.others.length, 0);
      final promoted = result.matches.first;
      expect(promoted['isNonMatch'], isFalse);
      expect(promoted['isFilterMatch'], isTrue);
      expect(promoted['mismatchReasons'], isEmpty);
      expect(promoted['bScore'], 0);
      expect(promoted['isOutsidePreference'], isFalse);
    });

    test('updates mismatch reasons for non-matches still failing constraints', () {
      final nonMatch = {
        'propertyId': 'p2',
        'monthlyRent': 6000,
        'distance': 2.0,
        'maxOccupants': 1,
        'isNonMatch': true,
        'bScore': 0,
        'mismatchReasons': [
          const MismatchReason(MismatchKind.overCapacity, 1),
          const MismatchReason(MismatchKind.overBudget, 2000),
        ],
      };

      final result = session.evaluate(
        matching: [],
        nonMatches: [nonMatch],
      );

      expect(result.matches.length, 0);
      expect(result.others.length, 1);
      final updated = result.others.first;
      expect(updated['isNonMatch'], isTrue);
      // overCapacity is resolved because groupSize is 1 and maxOccupants is 1.
      // overBudget remains, updated to 800 (6000 - 5200).
      final reasons = (updated['mismatchReasons'] as List).cast<MismatchReason>();
      expect(reasons.length, 1);
      expect(reasons.first.kind, MismatchKind.overBudget);
      expect(reasons.first.amount, 800);
    });

    test('moves matches failing explicit group size into others with reason', () {
      const groupSession = SearchSession(
        maxBudget: 6000,
        maxDistanceKm: 5,
        groupSize: 3,
      );

      final match = {
        'propertyId': 'm1',
        'monthlyRent': 4000,
        'distance': 2.0,
        'maxOccupants': 1,
        'isNonMatch': false,
        'bScore': 1,
      };

      final result = groupSession.evaluate(
        matching: [match],
        nonMatches: [],
      );

      expect(result.matches.length, 0);
      expect(result.others.length, 1);
      final demoted = result.others.first;
      expect(demoted['isNonMatch'], isTrue);
      final reasons = (demoted['mismatchReasons'] as List).cast<MismatchReason>();
      expect(reasons.first.kind, MismatchKind.overCapacity);
      expect(reasons.first.amount, 2);
    });
  });

  group('SearchSession.copyWith', () {
    test('copies with updated fields while preserving others', () {
      const session = SearchSession(
        maxBudget: 5000,
        maxDistanceKm: 3,
        roomType: 'Solo',
      );
      final updated = session.copyWith(maxBudget: 7000);
      expect(updated.maxBudget, 7000);
      expect(updated.maxDistanceKm, 3);
      expect(updated.roomType, 'Solo');
    });
  });


  group('matchesSearchQuery', () {
    final listing = _listing(
      'a',
      title: 'Sunshine Boarding House',
      address: 'Matina, Davao City',
    );

    test('matches title or address, case-insensitively', () {
      expect(matchesSearchQuery(listing, 'sunshine'), isTrue);
      expect(matchesSearchQuery(listing, 'MATINA'), isTrue);
      expect(matchesSearchQuery(listing, 'Buhangin'), isFalse);
    });

    test('a blank query matches everything', () {
      expect(matchesSearchQuery(listing, '   '), isTrue);
    });
  });
}
