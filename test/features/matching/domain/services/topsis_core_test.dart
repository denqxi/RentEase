import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/tenant_profile_doc.dart';
import 'package:rentease/features/matching/domain/services/topsis_core.dart';

List<TopsisRanking> _rank(
  List<TopsisAlternative> alts, [
  List<num> w = const [0.35, 0.35, 0.30],
]) => rankTopsis(
  alternatives: alts,
  weights: w,
  isBenefit: const [false, false, true],
);

void main() {
  group('tie-break', () {
    test('equal Ci orders by rent then id, stable across shuffles', () {
      const alts = [
        TopsisAlternative(id: 'b', values: [3000, 1.0, 5]),
        TopsisAlternative(id: 'a', values: [3000, 1.0, 5]),
        TopsisAlternative(id: 'c', values: [3000, 1.0, 5]),
        TopsisAlternative(id: 'z', values: [4000, 2.0, 8]),
      ];
      final expected = _rank(alts).map((r) => r.id).toList();
      expect(expected.sublist(0, 3).toSet(), {'a', 'b', 'c'});
      final tied = expected.where((i) => i != 'z').toList();
      expect(tied, ['a', 'b', 'c']);
      for (var seed = 0; seed < 20; seed++) {
        final shuffled = [...alts]..shuffle(Random(seed));
        expect(_rank(shuffled).map((r) => r.id).toList(), expected);
      }
    });
  });

  group('weights guard', () {
    const alts = [
      TopsisAlternative(id: 'P1', values: [3000, 1.0, 10]),
      TopsisAlternative(id: 'P2', values: [4000, 2.0, 5]),
      TopsisAlternative(id: 'P3', values: [5000, 3.0, 14]),
    ];
    final base = _rank(alts);

    test('unnormalized weights are divided by their sum', () {
      final r = _rank(alts, [35, 35, 30]);
      for (var i = 0; i < 3; i++) {
        expect(r[i].id, base[i].id);
        expect(r[i].ci, closeTo(base[i].ci, 1e-9));
      }
    });

    test('zero, negative-sum and NaN weights fall back to defaults', () {
      for (final w in [
        [0, 0, 0],
        [-1, -1, -1],
        [double.nan, 0.5, 0.5],
      ]) {
        final r = _rank(alts, w);
        for (var i = 0; i < 3; i++) {
          expect(r[i].id, base[i].id);
          expect(r[i].ci, closeTo(base[i].ci, 1e-9));
        }
      }
    });
  });

  test('TenantProfileDoc.fromMap falls back to 0.35/0.35/0.30', () {
    final doc = TenantProfileDoc.fromMap('t1', const {});
    expect(doc.wRent, 0.35);
    expect(doc.wDistance, 0.35);
    expect(doc.wAmenities, 0.30);
  });
}
