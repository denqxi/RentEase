import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Travel profile for routing.
enum RouteProfile {
  driving,
  walking;

  String get osrmKey => switch (this) {
        RouteProfile.driving => 'driving',
        RouteProfile.walking => 'walking',
      };

  String get label => switch (this) {
        RouteProfile.driving => 'Drive',
        RouteProfile.walking => 'Walk',
      };

  IconData get icon => switch (this) {
        RouteProfile.driving => Icons.directions_car_rounded,
        RouteProfile.walking => Icons.directions_walk_rounded,
      };
}

/// Maneuver type reported by routing engine.
enum ManeuverType {
  depart,
  arrive,
  turn,
  continueStraight,
  fork,
  merge,
  roundabout,
  endOfRoad,
  ramp,
  unknown;

  static ManeuverType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'depart':
        return ManeuverType.depart;
      case 'arrive':
        return ManeuverType.arrive;
      case 'turn':
        return ManeuverType.turn;
      case 'new name':
      case 'continue':
        return ManeuverType.continueStraight;
      case 'fork':
        return ManeuverType.fork;
      case 'merge':
        return ManeuverType.merge;
      case 'roundabout':
      case 'rotary':
        return ManeuverType.roundabout;
      case 'end of road':
        return ManeuverType.endOfRoad;
      case 'ramp':
      case 'on ramp':
      case 'off ramp':
        return ManeuverType.ramp;
      default:
        return ManeuverType.unknown;
    }
  }
}

/// Detailed turn-by-turn maneuver instruction.
class NavigationManeuver {
  final ManeuverType type;
  final String? modifier;
  final LatLng location;
  final String instruction;

  const NavigationManeuver({
    required this.type,
    required this.modifier,
    required this.location,
    required this.instruction,
  });

  /// Resolves the corresponding turn arrow icon based on maneuver and modifier.
  IconData get icon {
    final mod = modifier?.toLowerCase() ?? '';
    switch (type) {
      case ManeuverType.arrive:
        return Icons.place_rounded;
      case ManeuverType.depart:
        return Icons.navigation_rounded;
      case ManeuverType.roundabout:
        return Icons.roundabout_right_rounded;
      case ManeuverType.fork:
        if (mod.contains('left')) return Icons.fork_left_rounded;
        return Icons.fork_right_rounded;
      case ManeuverType.turn:
      default:
        if (mod.contains('sharp left')) return Icons.turn_sharp_left_rounded;
        if (mod.contains('sharp right')) return Icons.turn_sharp_right_rounded;
        if (mod.contains('slight left')) return Icons.turn_slight_left_rounded;
        if (mod.contains('slight right')) return Icons.turn_slight_right_rounded;
        if (mod.contains('left')) return Icons.turn_left_rounded;
        if (mod.contains('right')) return Icons.turn_right_rounded;
        if (mod.contains('u-turn') || mod.contains('uturn')) return Icons.u_turn_left_rounded;
        return Icons.straight_rounded;
    }
  }
}

/// A single step in the turn-by-turn itinerary.
class NavigationStep {
  final double distanceMeters;
  final double durationSeconds;
  final String roadName;
  final NavigationManeuver maneuver;

  const NavigationStep({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.roadName,
    required this.maneuver,
  });

  /// Readable distance string (e.g. "250 m" or "1.4 km").
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  /// Readable step title for the top HUD banner.
  String get displayInstruction {
    if (maneuver.type == ManeuverType.arrive) {
      return 'You will arrive at your destination';
    }
    if (maneuver.type == ManeuverType.depart) {
      return roadName.isNotEmpty ? 'Head out on $roadName' : 'Head toward destination';
    }
    final mod = maneuver.modifier ?? '';
    final action = mod.isNotEmpty ? 'Turn $mod' : 'Continue';
    if (roadName.isNotEmpty) {
      return '$action onto $roadName';
    }
    return '$action along route';
  }
}

/// Complete route plan containing polyline geometry, overall metrics, and steps.
class RoutePlan {
  final List<LatLng> points;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final List<NavigationStep> steps;
  final RouteProfile profile;

  const RoutePlan({
    required this.points,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.steps,
    required this.profile,
  });

  /// Formatted total distance (e.g. "2.4 km").
  String get formattedTotalDistance {
    if (totalDistanceMeters < 1000) {
      return '${totalDistanceMeters.round()} m';
    }
    return '${(totalDistanceMeters / 1000).toStringAsFixed(1)} km';
  }

  /// Formatted duration (e.g. "8 min" or "1 hr 15 min").
  String get formattedDuration {
    final minutes = (totalDurationSeconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMin = minutes % 60;
    if (remainingMin == 0) return '$hours hr';
    return '$hours hr $remainingMin min';
  }

  /// Estimated arrival clock time (e.g. "8:45 PM").
  String get formattedEta {
    final etaTime = DateTime.now().add(Duration(seconds: totalDurationSeconds.round()));
    final hour = etaTime.hour;
    final minute = etaTime.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute ${isPm ? 'PM' : 'AM'}';
  }
}
