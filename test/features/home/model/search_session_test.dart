import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/features/home/model/search_session.dart';

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
