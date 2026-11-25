import 'package:equatable/equatable.dart';

enum Priority { rent, distance, amenities }

/// The tenant's three ranking priorities as whole percentages.
class PriorityWeights extends Equatable {
  const PriorityWeights({
    required this.rent,
    required this.distance,
    required this.amenities,
  });

  final int rent;
  final int distance;
  final int amenities;

  /// Slider step, in percentage points.
  static const int step = 5;

  int get total => rent + distance + amenities;

  int operator [](Priority p) => switch (p) {
    Priority.rent => rent,
    Priority.distance => distance,
    Priority.amenities => amenities,
  };

  /// Sets [changed] to [value] (snapped to [step], 0–100) and shares what is
  /// left between the other two in their current proportion, or equally when
  /// both are zero. The result always totals 100.
  ///
  /// During a drag, call this on the weights held when the drag started, so
  /// repeated rounding cannot drift the other two's proportion.
  PriorityWeights rebalance(Priority changed, num value) {
    final next = ((value / step).round() * step).clamp(0, 100);
    final remaining = 100 - next;
    final [first, second] = [
      for (final p in Priority.values)
        if (p != changed) p,
    ];
    final pair = this[first] + this[second];
    final share = pair == 0 ? remaining / 2 : remaining * this[first] / pair;
    final firstValue = ((share / step).round() * step).clamp(0, remaining);
    final values = {
      changed: next,
      first: firstValue,
      second: remaining - firstValue,
    };
    return PriorityWeights(
      rent: values[Priority.rent]!,
      distance: values[Priority.distance]!,
      amenities: values[Priority.amenities]!,
    );
  }

  @override
  List<Object?> get props => [rent, distance, amenities];
}
