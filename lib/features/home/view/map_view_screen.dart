import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_options.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../cubit/home_cubit.dart';
import '../model/navigation_models.dart';
import '../services/navigation_service.dart';
import '../widgets/listing_card_large.dart';
import '../widgets/live_navigation_bottom_bar.dart';
import '../widgets/live_user_puck.dart';
import 'property_detail_screen.dart';

/// Google Maps light-mode aesthetic color matrix filter applied directly to
/// standard OpenStreetMap tiles. Renders clean light off-white landmass,
/// preserves warm yellow highway and main road tints, enriches park greenery,
/// and softens water into a calm Google Maps cyan-blue.
/// Requires NO API key and has ZERO watermarks.
const ColorFilter _kOsmGoogleMapsLightFilter = ColorFilter.matrix(<double>[
  0.88, 0.12, -0.06, 0, 14, // R (Preserves warm red in yellow roads & parks)
  0.06, 0.94, -0.04, 0, 14, // G (Enhances natural green park foliage & yellow roads)
  -0.08, 0.08, 0.88, 0, 24, // B (Suppresses blue in land/roads while keeping water crisp & calm)
  0,     0,     0,   1,  0, // A
]);

/// Map browsing view featuring:
/// - Desaturated, clean Google Maps light-mode aesthetic (Option 2).
/// - Destination POI with concentric circle and exact center-anchored badge.
/// - Dynamic POI icons (graduation hat for school, suitcase for work, pin for other).
/// - Small, minimal property pins with navbar home icon, compact percentage capsules,
///   crisp white outlines, and subtle pastel match tiers (reserving cyan blue for selection & POI).
/// - 3-step navigation flow matching the reference design.
class MapViewScreen extends StatefulWidget {
  const MapViewScreen({
    required this.properties,
    this.isGuest = false,
    this.poi,
    this.poiLabel,
    this.poiType,
    this.homeCubit,
    this.initialPropertyId,
    this.isSinglePropertyMode = false,
    super.key,
  });

  final List<Map<String, dynamic>> properties;

  /// Opens pins' detail screens in the gated guest mode.
  final bool isGuest;

  /// The tenant's saved point of interest; null for guests / no profile, in
  /// which case the map centers on Davao City and shows no POI marker.
  final LatLng? poi;
  final String? poiLabel;
  final String? poiType;

  /// Passed on to the detail screens so their heart works.
  final HomeCubit? homeCubit;

  /// Optional propertyId to focus and select immediately upon opening map.
  final String? initialPropertyId;

  /// When opened directly from a property detail screen:
  /// Locks selection to this single property, keeps bottom card permanently open,
  /// hides "Properties near" button, and shows destination POI without overlap.
  final bool isSinglePropertyMode;

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final _mapController = MapController();
  int? _selectedIndex;
  Map<String, dynamic>? _lastSelectedProperty;

  // ── Live Navigation State ──────────────────────────────────────────────────
  final _navigationService = NavigationService();
  bool _isNavigating = false;
  bool _isLoadingRoute = false;
  RoutePlan? _currentRoutePlan;
  RouteProfile _currentProfile = RouteProfile.driving;
  LatLng? _userLocation;
  double? _userHeading;
  StreamSubscription<Position>? _positionSubscription;
  bool _isCameraTrackingUser = true;

  // In-memory route plan cache keyed by "originLat,originLng_destLat,destLng_profile"
  final Map<String, RoutePlan> _routePlanCache = {};



  @override
  void initState() {
    super.initState();
    if (widget.isSinglePropertyMode && widget.properties.isNotEmpty) {
      _selectedIndex = 0;
      _lastSelectedProperty = widget.properties.first;
    } else if (widget.initialPropertyId != null) {
      final idx = widget.properties.indexWhere(
        (p) => p['propertyId'] == widget.initialPropertyId,
      );
      if (idx != -1) {
        _selectedIndex = idx;
        _lastSelectedProperty = widget.properties[idx];
      }
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Begins Google Maps-style live turn-by-turn navigation to [property].
  Future<void> _startNavigation(Map<String, dynamic> property) async {
    final destLat = (property['latitude'] as num?)?.toDouble();
    final destLng = (property['longitude'] as num?)?.toDouble();
    if (destLat == null || destLng == null || destLat == 0.0 || destLng == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Property coordinates are unavailable for navigation',
            style: TextStyle(fontFamily: 'DM Sans'),
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final destination = LatLng(destLat, destLng);

    setState(() {
      _isNavigating = true;
      _isLoadingRoute = true;
      _isCameraTrackingUser = true;
    });

    // 1. Resolve starting origin: strictly use tenant's saved POI if available; fallback to user GPS or Davao default
    LatLng origin;
    if (widget.poi != null) {
      origin = widget.poi!;
    } else {
      origin = const LatLng(AppOptions.defaultMapLat, AppOptions.defaultMapLng);
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 4),
            ),
          );
          origin = LatLng(pos.latitude, pos.longitude);
          _userLocation = origin;
          _userHeading = pos.heading > 0 ? pos.heading : null;
        }
      } catch (_) {
        // Fallback to origin
      }
    }

    if (!mounted) return;
    _userLocation ??= origin;

    // 2. Fetch OSRM road route geometry (served instantly from in-memory cache if previously queried)
    final cacheKey =
        '${origin.latitude.toStringAsFixed(4)},${origin.longitude.toStringAsFixed(4)}_${destination.latitude.toStringAsFixed(4)},${destination.longitude.toStringAsFixed(4)}_${_currentProfile.name}';
    RoutePlan? plan = _routePlanCache[cacheKey];
    if (plan == null) {
      plan = await _navigationService.fetchRoute(
        origin: origin,
        destination: destination,
        profile: _currentProfile,
      );
      if (plan != null) {
        _routePlanCache[cacheKey] = plan;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoadingRoute = false;
      _currentRoutePlan = plan;
    });

    // 3. Fit initial camera bounds between POI origin and property
    if (plan != null && plan.points.length >= 2) {
      try {
        final bounds = LatLngBounds.fromPoints(plan.points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.only(top: 80, bottom: 260, left: 45, right: 45),
          ),
        );
      } catch (_) {
        _mapController.move(origin, 15.0);
      }
    }

    // Cancel any previous live position subscription: in-app view is a POI preview
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _onProfileChanged(RouteProfile newProfile) async {
    if (_currentProfile == newProfile) return;
    setState(() {
      _currentProfile = newProfile;
      _isLoadingRoute = true;
    });

    final active = _lastSelectedProperty;
    if (active == null) {
      setState(() => _isLoadingRoute = false);
      return;
    }

    final destLat = (active['latitude'] as num?)?.toDouble() ?? 0.0;
    final destLng = (active['longitude'] as num?)?.toDouble() ?? 0.0;
    final dest = LatLng(destLat, destLng);
    final origin = widget.poi ?? _userLocation ?? const LatLng(AppOptions.defaultMapLat, AppOptions.defaultMapLng);

    final cacheKey =
        '${origin.latitude.toStringAsFixed(4)},${origin.longitude.toStringAsFixed(4)}_${dest.latitude.toStringAsFixed(4)},${dest.longitude.toStringAsFixed(4)}_${newProfile.name}';
    RoutePlan? plan = _routePlanCache[cacheKey];
    if (plan == null) {
      plan = await _navigationService.fetchRoute(
        origin: origin,
        destination: dest,
        profile: newProfile,
      );
      if (plan != null) {
        _routePlanCache[cacheKey] = plan;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoadingRoute = false;
      _currentRoutePlan = plan;
    });

    if (plan != null && plan.points.length >= 2) {
      try {
        final bounds = LatLngBounds.fromPoints(plan.points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.only(top: 80, bottom: 260, left: 45, right: 45),
          ),
        );
      } catch (_) {}
    }
  }

  void _exitNavigation() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    setState(() {
      _isNavigating = false;
      _isLoadingRoute = false;
      _currentRoutePlan = null;
    });

    // Re-center on property with default viewing offset
    if (_lastSelectedProperty != null) {
      final lat = (_lastSelectedProperty!['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (_lastSelectedProperty!['longitude'] as num?)?.toDouble() ?? 0.0;
      if (lat != 0.0 && lng != 0.0) {
        _mapController.move(LatLng(lat - 0.0035, lng), 15.5);
      }
    }
  }

  void _launchGoogleMaps() {
    if (_lastSelectedProperty == null) return;
    final lat = (_lastSelectedProperty!['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (_lastSelectedProperty!['longitude'] as num?)?.toDouble() ?? 0.0;
    _navigationService.launchExternalGoogleMaps(
      destination: LatLng(lat, lng),
      origin: null, // Left null so Google Maps uses device's live GPS location for real-time guidance
      profile: _currentProfile,
    );
  }

  LatLng _resolveInitialCenter() {
    if (_selectedIndex != null && _selectedIndex! < widget.properties.length) {
      final p = widget.properties[_selectedIndex!];
      final lat = (p['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (p['longitude'] as num?)?.toDouble() ?? 0.0;
      if (lat != 0.0 && lng != 0.0) {
        // Offset southward slightly so the pin stays centered above the bottom card.
        return LatLng(lat - 0.0035, lng);
      }
    }
    return widget.poi ??
        const LatLng(
          AppOptions.defaultMapLat,
          AppOptions.defaultMapLng,
        );
  }

  void _onPinTapped(int index) {
    if (index >= 0 && index < widget.properties.length) {
      final p = widget.properties[index];
      setState(() {
        _selectedIndex = index;
        _lastSelectedProperty = p;
      });

      final lat = (p['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (p['longitude'] as num?)?.toDouble() ?? 0.0;
      if (lat != 0.0 && lng != 0.0) {
        // Offset southward slightly so the pin stays visible above the bottom preview card.
        _mapController.move(LatLng(lat - 0.0035, lng), 15.5);
      }
    }
  }

  void _dismissSelection() {
    if (widget.isSinglePropertyMode) return;
    if (_selectedIndex != null) {
      setState(() {
        _selectedIndex = null;
      });
    }
  }

  void _openNearbyPropertiesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _NearbyPropertiesSheet(
        properties: widget.properties,
        poiLabel: widget.poiLabel,
        poiType: widget.poiType,
        isGuest: widget.isGuest,
        onSelectProperty: (property) {
          Navigator.of(sheetContext).pop();
          final idx = widget.properties.indexOf(property);
          if (idx != -1) {
            _onPinTapped(idx);
          }
        },
      ),
    );
  }

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  IconData _resolvePoiIcon() {
    final l = (widget.poiLabel ?? '').toLowerCase();
    final t = (widget.poiType ?? '').toLowerCase();
    if (t == 'school' ||
        l.contains('school') ||
        l.contains('college') ||
        l.contains('university') ||
        l.contains('campus') ||
        l.contains('academy')) {
      return Icons.school_outlined;
    }
    if (t == 'work' ||
        l.contains('office') ||
        l.contains('work') ||
        l.contains('corp') ||
        l.contains('building') ||
        l.contains('company')) {
      return Icons.work_outline_rounded;
    }
    return Icons.place_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final properties = widget.properties;
    final activeProperty = _selectedIndex != null && _selectedIndex! < properties.length
        ? properties[_selectedIndex!]
        : _lastSelectedProperty;

    return PopScope(
      canPop: !_isNavigating,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isNavigating) {
          _exitNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            // ── Edge-to-Edge Interactive Map with Google Maps Light Filter ──
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _resolveInitialCenter(),
                  initialZoom: _selectedIndex != null ? 15.5 : 13.5,
                  // Tapping empty map space dismisses selected property card.
                  onTap: (_, _) => _dismissSelection(),
                  onPositionChanged: (camera, hasGesture) {
                    if (hasGesture && _isNavigating && _isCameraTrackingUser) {
                      setState(() {
                        _isCameraTrackingUser = false;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.rentease.app',
                    tileBuilder: (context, tileWidget, tile) {
                      return ColorFiltered(
                        colorFilter: _kOsmGoogleMapsLightFilter,
                        child: tileWidget,
                      );
                    },
                  ),

                  // ── Live Navigation Route Polyline with Google Maps Casing ──
                  if (_isNavigating &&
                      _currentRoutePlan != null &&
                      _currentRoutePlan!.points.length >= 2)
                    PolylineLayer(
                      polylines: [
                        // Base casing polyline (darker blue border for contrast)
                        Polyline(
                          points: _currentRoutePlan!.points,
                          strokeWidth: 7.5,
                          color: const Color(0xFF1557B0),
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                        ),
                        // Inner route polyline (vibrant Google Maps navigation blue)
                        Polyline(
                          points: _currentRoutePlan!.points,
                          strokeWidth: 5.0,
                          color: const Color(0xFF1A73E8),
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                        ),
                      ],
                    ),

                  MarkerLayer(
                  markers: [
                    // Tenant POI marker — exactly anchored to widget.poi!
                    if (widget.poi != null &&
                        !(widget.isSinglePropertyMode &&
                            properties.isNotEmpty &&
                            (widget.poi!.latitude - (properties.first['latitude'] as num).toDouble()).abs() < 0.0001 &&
                            (widget.poi!.longitude - (properties.first['longitude'] as num).toDouble()).abs() < 0.0001))
                      Marker(
                        point: widget.poi!,
                        width: 260,
                        height: 110,
                        alignment: Alignment.bottomCenter,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Destination Label Card with Icon and Subtitle
                              Container(
                                margin: const EdgeInsets.only(bottom: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                constraints: const BoxConstraints(maxWidth: 240),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 0.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Light soft blue circular container with destination icon
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE0F2FE),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _resolvePoiIcon(),
                                          size: 12,
                                          color: const Color(0xFF0284C7),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    // Title & Location Subtitle
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.poiLabel?.isNotEmpty == true
                                                ? widget.poiLabel!
                                                : 'Your Destination',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'DM Sans',
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                              letterSpacing: -0.1,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          const Text(
                                            'Davao City',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'DM Sans',
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Connecting tiny dot directly below card
                              Container(
                                width: 4.5,
                                height: 4.5,
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0284C7),
                                  shape: BoxShape.circle,
                                ),
                              ),

                              // Concentric rings with circular badge anchored to coordinates
                              SizedBox(
                                width: 38,
                                height: 38,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer subtle ring
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                      ),
                                    ),
                                    // Middle subtle ring
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.22),
                                      ),
                                    ),
                                    // Core solid blue circular badge with white outline
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1.5),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _resolvePoiIcon(),
                                          color: Colors.white,
                                          size: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Unselected property markers — anchored exactly to coordinates with ample headroom
                    for (int i = 0; i < properties.length; i++)
                      if (i != _selectedIndex)
                        Marker(
                          point: LatLng(
                            (properties[i]['latitude'] as num).toDouble(),
                            (properties[i]['longitude'] as num).toDouble(),
                          ),
                          width: 52,
                          height: 62,
                          alignment: Alignment.bottomCenter,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _PropertyPinMarker(
                              property: properties[i],
                              isSelected: false,
                              onTap: () => _onPinTapped(i),
                            ),
                          ),
                        ),

                    // Selected property marker rendered LAST so it sits on top with cyan halo
                    if (_selectedIndex != null && _selectedIndex! < properties.length)
                      Marker(
                        point: LatLng(
                          (properties[_selectedIndex!]['latitude'] as num).toDouble(),
                          (properties[_selectedIndex!]['longitude'] as num).toDouble(),
                        ),
                        width: 62,
                        height: 72,
                        alignment: Alignment.bottomCenter,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _PropertyPinMarker(
                            property: properties[_selectedIndex!],
                            isSelected: true,
                            onTap: () => _onPinTapped(_selectedIndex!),
                          ),
                        ),
                      ),

                    // Live Navigation User Puck with Heading Cone (only shown if navigating without a POI)
                    if (_isNavigating && widget.poi == null && _userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        child: LiveUserPuck(
                          heading: _userHeading,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Top Bar: Compact Back Button Pill (Consistent UX) ─────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button & Screen Title Pill (Entire container clickable)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_isNavigating) {
                        _exitNavigation();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.fromLTRB(8, 3, 14, 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: Color(0xFF0F172A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isNavigating ? 'Route preview' : 'Map view',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                  // Current Location Button (centers to user POI or initial center)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final center = _resolveInitialCenter();
                        _mapController.move(center, 14.5);
                      },
                      borderRadius: BorderRadius.circular(19),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          size: 18,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Zoom Controls (Clean minimal pill on the right side) ─────────
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.42,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      final camera = _mapController.camera;
                      _mapController.move(camera.center, camera.zoom + 1);
                    },
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(Icons.add_rounded, size: 18, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
                  InkWell(
                    onTap: () {
                      final camera = _mapController.camera;
                      _mapController.move(camera.center, camera.zoom - 1);
                    },
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(Icons.remove_rounded, size: 18, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Screen 1: Clean, Compact Bottom Button ───────────────────────
          if (!_isNavigating && !widget.isSinglePropertyMode && _selectedIndex == null)
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: InkWell(
                onTap: _openNearbyPropertiesSheet,
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const AppSvgIcon(
                        svgString: AppSvgIcons.mapBuildingHouse,
                        size: 21,
                        color: Color(0xFF00A8F0),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Properties near your destination',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Screen 3: Selected Property Preview Bottom Card ───────────────
          if (!_isNavigating && _selectedIndex != null && activeProperty != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _PropertyPreviewBottomCard(
                property: activeProperty,
                isGuest: widget.isGuest,
                homeCubit: widget.homeCubit,
                initialPropertyId: widget.initialPropertyId,
                poi: widget.poi,
                fmt: _fmt,
                onDirectionsTap: () => _startNavigation(activeProperty),
              ),
            ),

          // ── Route Preview: Fit Route Bounds Floating Button ─────────────
          if (_isNavigating && _currentRoutePlan != null && _currentRoutePlan!.points.length >= 2)
            Positioned(
              right: 16,
              bottom: 235 + MediaQuery.of(context).padding.bottom,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: 0.15),
                child: InkWell(
                  onTap: () {
                    try {
                      final bounds = LatLngBounds.fromPoints(_currentRoutePlan!.points);
                      _mapController.fitCamera(
                        CameraFit.bounds(
                          bounds: bounds,
                          padding: const EdgeInsets.only(top: 80, bottom: 260, left: 45, right: 45),
                        ),
                      );
                    } catch (_) {}
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.crop_free_rounded,
                      size: 20,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ),

          // ── Route Preview: Bottom Trip Summary & Mode Bar ──────────────
          if (_isNavigating)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LiveNavigationBottomBar(
                routePlan: _currentRoutePlan,
                currentProfile: _currentProfile,
                isLoadingRoute: _isLoadingRoute,
                onProfileChanged: _onProfileChanged,
                onExit: _exitNavigation,
                onLaunchGoogleMaps: _launchGoogleMaps,
                destinationName: (activeProperty?['propertyName'] as String?) ??
                    (activeProperty?['title'] as String?) ??
                    'Destination',
                destinationAddress: (activeProperty?['address'] as String?) ?? 'Davao City',
                originName: widget.poiLabel ?? 'Your POI',
                originAddress: 'Davao City',
              ),
            ),
        ],
      ),
    ),
  );
  }
}

/// Small, minimal teardrop pin with navbar home icon, compact percentage capsule,
/// crisp white outline, and animated pulse effect when selected.
class _PropertyPinMarker extends StatefulWidget {
  const _PropertyPinMarker({
    required this.property,
    required this.isSelected,
    required this.onTap,
  });

  final Map<String, dynamic> property;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_PropertyPinMarker> createState() => _PropertyPinMarkerState();
}

class _PropertyPinMarkerState extends State<_PropertyPinMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScaleAnimation;
  late final Animation<double> _pulseOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseScaleAnimation = Tween<double>(begin: 0.85, end: 1.55).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOutQuad,
      ),
    );

    _pulseOpacityAnimation = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOutQuad,
      ),
    );

    if (widget.isSelected) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _PropertyPinMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _pulseController.repeat();
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double ci = (widget.property['tenantCi'] as num?)?.toDouble() ?? 0.0;
    final int percent = (ci * 100).round();
    final tier = _SubtleTierColor.forPercent(percent);

    final double pinW = widget.isSelected ? 22 : 18.5;
    final double pinH = widget.isSelected ? 31 : 26;
    final double iconSize = widget.isSelected ? 13.5 : 11.0;
    const Color lightCyanBlue = Color(0xFF00A8F0);

    final Color pinFillColor = widget.isSelected ? lightCyanBlue : Colors.white;
    final Color pinStrokeColor = widget.isSelected ? Colors.white : lightCyanBlue;
    final Color pinIconColor = widget.isSelected ? Colors.white : lightCyanBlue;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Animated Pulse Effect when selected
          if (widget.isSelected)
            Positioned(
              bottom: -4,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _pulseScaleAnimation.value,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: lightCyanBlue.withValues(
                          alpha: _pulseOpacityAnimation.value,
                        ),
                        border: Border.all(
                          color: lightCyanBlue.withValues(
                            alpha: _pulseOpacityAnimation.value * 0.8,
                          ),
                          width: 1.1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Secondary subtle inner glow ring
          if (widget.isSelected)
            Positioned(
              bottom: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lightCyanBlue.withValues(alpha: 0.15),
                ),
              ),
            ),

          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Compact Percentage Capsule (subtle tier bg, unchanged color on selection)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.0),
                decoration: BoxDecoration(
                  color: tier.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tier.borderColor,
                    width: 0.9,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: widget.isSelected ? 10.5 : 10,
                    fontWeight: FontWeight.w700,
                    color: tier.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 1.0),

              // Teardrop Pin (slimmer & smaller, dynamic active colors, unchanged % badge)
              SizedBox(
                width: pinW,
                height: pinH,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _TeardropPinPainter(
                          fillColor: pinFillColor,
                          strokeColor: pinStrokeColor,
                          strokeWidth: widget.isSelected ? 1.2 : 1.0,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0.5,
                      left: 0,
                      right: 0,
                      height: pinW,
                      child: Center(
                        child: AppSvgIcon(
                          svgString: AppSvgIcons.mapBuildingHouse,
                          size: iconSize,
                          color: pinIconColor,
                          strokeWidth: 2.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A compact teardrop-shaped map pin with a curved dome top and pointed bottom tip.
class _TeardropPinPainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  const _TeardropPinPainter({
    required this.fillColor,
    this.strokeColor = Colors.white,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;

    final path = Path()
      ..moveTo(r, h)
      ..cubicTo(r * 0.28, h * 0.74, 0, r * 1.25, 0, r)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r), clockwise: true)
      ..cubicTo(w, r * 1.25, w - (r * 0.28), h * 0.74, r, h)
      ..close();

    // Soft blurred ambient drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawPath(path.shift(const Offset(0, 1.4)), shadowPaint);

    // Elevated shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.16), 2.2, false);

    // Fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Stroke Outline
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _TeardropPinPainter oldDelegate) =>
      fillColor != oldDelegate.fillColor ||
      strokeColor != oldDelegate.strokeColor ||
      strokeWidth != oldDelegate.strokeWidth;
}

/// Screen 2: Clean Nearby Properties Bottom Sheet (with zero horizontal overflow)
class _NearbyPropertiesSheet extends StatefulWidget {
  const _NearbyPropertiesSheet({
    required this.properties,
    required this.poiLabel,
    required this.poiType,
    required this.isGuest,
    required this.onSelectProperty,
  });

  final List<Map<String, dynamic>> properties;
  final String? poiLabel;
  final String? poiType;
  final bool isGuest;
  final ValueChanged<Map<String, dynamic>> onSelectProperty;

  @override
  State<_NearbyPropertiesSheet> createState() => _NearbyPropertiesSheetState();
}

enum _SortOption { nearest, highestMatch }

class _NearbyPropertiesSheetState extends State<_NearbyPropertiesSheet> {
  _SortOption _sortBy = _SortOption.nearest;

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  IconData _resolvePoiIcon() {
    final l = (widget.poiLabel ?? '').toLowerCase();
    final t = (widget.poiType ?? '').toLowerCase();
    if (t == 'school' ||
        l.contains('school') ||
        l.contains('college') ||
        l.contains('university')) {
      return Icons.school_outlined;
    }
    if (t == 'work' ||
        l.contains('office') ||
        l.contains('work')) {
      return Icons.work_outline_rounded;
    }
    return Icons.place_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final sortedList = List<Map<String, dynamic>>.from(widget.properties);
    if (_sortBy == _SortOption.nearest) {
      sortedList.sort((a, b) {
        final distA = (a['distance'] as num?)?.toDouble() ?? 999.0;
        final distB = (b['distance'] as num?)?.toDouble() ?? 999.0;
        return distA.compareTo(distB);
      });
    } else {
      sortedList.sort((a, b) {
        final ciA = (a['tenantCi'] as num?)?.toDouble() ?? 0.0;
        final ciB = (b['tenantCi'] as num?)?.toDouble() ?? 0.0;
        return ciB.compareTo(ciA);
      });
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: 16sp Semibold Section Heading & Count Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Properties near your destination',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.properties.length} nearby',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Destination Row with dynamic outline icon
          Row(
            children: [
              Icon(
                _resolvePoiIcon(),
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.poiLabel?.isNotEmpty == true
                      ? widget.poiLabel!
                      : 'Your Destination',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sort Filter Pills: Nearest first & Highest match
          Row(
            children: [
              _FilterPill(
                label: 'Nearest first',
                isSelected: _sortBy == _SortOption.nearest,
                onTap: () => setState(() => _sortBy = _SortOption.nearest),
              ),
              const SizedBox(width: 8),
              _FilterPill(
                label: 'Highest match',
                isSelected: _sortBy == _SortOption.highestMatch,
                onTap: () => setState(() => _sortBy = _SortOption.highestMatch),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scrollable List of Property Cards (with robust flex layout to prevent overflow)
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: sortedList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final property = sortedList[index];
                final rawTitle = (property['title'] as String?) ?? 'Property';
                final (propName, roomOrTitle) = ListingCardLarge.resolveTitles(
                  rawTitle: rawTitle,
                  explicitPropertyName: property['propertyName'] as String?,
                  explicitRoomName: property['roomName'] as String?,
                );

                final monthlyRent = (property['monthlyRent'] as num?)?.round() ?? 0;
                final dist = (property['distance'] as num?)?.toDouble();
                final double ci = (property['tenantCi'] as num?)?.toDouble() ?? 0.0;
                final int percent = (ci * 100).round();
                final tier = _SubtleTierColor.forPercent(percent);

                final photoUrl = (property['photoUrl'] as String?) ??
                    ((property['photos'] as List?)?.firstOrNull as String?) ??
                    ((property['photoUrls'] as List?)?.firstOrNull as String?);
                final seed = (property['propertyId'] as String?)?.hashCode.abs() ?? index;

                return InkWell(
                  onTap: () => widget.onSelectProperty(property),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Thumbnail (68x68, rounded 10)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 68,
                            height: 68,
                            child: ListingImagePlaceholder(
                              seed: seed,
                              photoUrl: photoUrl,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Middle Info Column (Expanded to ensure zero overflow)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Line 1: Property Name (14sp semibold, dark navy)
                              Text(
                                propName ?? roomOrTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Line 2: Room / Location (11.5sp, muted gray)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      propName != null
                                          ? roomOrTitle
                                          : ((property['address'] as String?) ?? 'Davao City'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),

                              // Line 3: Distance from destination (11sp, muted gray)
                              if (dist != null) ...[
                                Text(
                                  '${dist.toStringAsFixed(1)} km from destination',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 3),
                              ],

                              // Line 4: Price with app theme primary blue rent and gray unbolded /month
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '₱${_fmt(monthlyRent)}',
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' / month',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Right: Match % Rounded Pill Badge & Chevron
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: tier.bg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: tier.borderColor, width: 0.8),
                              ),
                              child: Text(
                                '$percent%',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: tier.textColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

/// Screen 3: Selected Property Preview Bottom Card (prominent primary action)
class _PropertyPreviewBottomCard extends StatefulWidget {
  const _PropertyPreviewBottomCard({
    required this.property,
    required this.isGuest,
    required this.homeCubit,
    required this.initialPropertyId,
    required this.fmt,
    this.poi,
    this.onDirectionsTap,
  });

  final Map<String, dynamic> property;
  final bool isGuest;
  final HomeCubit? homeCubit;
  final String? initialPropertyId;
  final String Function(num) fmt;
  final LatLng? poi;
  final VoidCallback? onDirectionsTap;

  @override
  State<_PropertyPreviewBottomCard> createState() => _PropertyPreviewBottomCardState();
}

class _PropertyPreviewBottomCardState extends State<_PropertyPreviewBottomCard> {
  bool _isAddressExpanded = false;

  @override
  void didUpdateWidget(covariant _PropertyPreviewBottomCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.property['propertyId'] != oldWidget.property['propertyId']) {
      _isAddressExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final isGuest = widget.isGuest;
    final homeCubit = widget.homeCubit;
    final initialPropertyId = widget.initialPropertyId;
    final fmt = widget.fmt;
    final poi = widget.poi;

    final rawTitle = (property['title'] as String?) ?? 'Property';
    final (propName, roomOrTitle) = ListingCardLarge.resolveTitles(
      rawTitle: rawTitle,
      explicitPropertyName: property['propertyName'] as String?,
      explicitRoomName: property['roomName'] as String?,
    );

    final String rawAddr = (property['address'] as String?)?.trim() ?? '';
    final String displayAddress = rawAddr.isNotEmpty
        ? rawAddr
        : (propName != null ? roomOrTitle : 'Davao City');

    final monthlyRent = (property['monthlyRent'] as num?)?.round() ?? 0;
    final propLat = (property['latitude'] as num?)?.toDouble();
    final propLng = (property['longitude'] as num?)?.toDouble();
    double? dist = (property['distance'] as num?)?.toDouble();
    if ((dist == null || dist == 0.0) && propLat != null && propLng != null && poi != null) {
      dist = const Distance().as(LengthUnit.Kilometer, LatLng(propLat, propLng), poi);
    }
    final double ci = (property['tenantCi'] as num?)?.toDouble() ?? 0.0;
    final int percent = (ci * 100).round();
    final tier = _SubtleTierColor.forPercent(percent);

    final photoUrl = (property['photoUrl'] as String?) ??
        ((property['photos'] as List?)?.firstOrNull as String?) ??
        ((property['photoUrls'] as List?)?.firstOrNull as String?);
    final rawPhotos = property['photos'] as List? ?? property['photoUrls'] as List?;
    final int photoCount = (rawPhotos != null && rawPhotos.isNotEmpty)
        ? rawPhotos.length
        : (photoUrl != null && photoUrl.isNotEmpty ? 1 : 1);
    final seed = (property['propertyId'] as String?)?.hashCode.abs() ?? 1;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Pop-up Card Container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            MediaQuery.of(context).padding.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 2, bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Main Info Row: Thumbnail on left, details on right
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Thumbnail (74x74, rounded 12)
                  SizedBox(
                    width: 74,
                    height: 74,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ListingImagePlaceholder(
                            seed: seed,
                            photoUrl: photoUrl,
                          ),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '1/$photoCount',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title, Room Subtitle, Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Property Name: 14sp semibold, dark navy
                            Expanded(
                              child: Text(
                                propName ?? roomOrTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: tier.bg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: tier.borderColor, width: 0.8),
                              ),
                              child: Text(
                                '$percent%',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: tier.textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),

                        // Room / Address: 11.5sp, muted gray (tap to view full address on next line)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _isAddressExpanded = !_isAddressExpanded;
                            });
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1.5),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    displayAddress,
                                    maxLines: _isAddressExpanded ? null : 1,
                                    overflow: _isAddressExpanded
                                        ? TextOverflow.visible
                                        : TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Price: Rent number in app theme primary blue, /month small & unbolded gray
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '₱${fmt(monthlyRent)}',
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const TextSpan(
                                text: ' / month',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Action Buttons: Directions on the left, View Details on the right
              // Locked to identical height (42px), border radius (10px), font size, and visual weight
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (widget.onDirectionsTap != null) {
                            widget.onDirectionsTap!();
                          } else {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Directions feature coming soon',
                                  style: TextStyle(fontFamily: 'DM Sans'),
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const AppSvgIcon(
                          svgString: AppSvgIcons.googleMaps,
                          size: 16.5,
                          color: AppColors.primary,
                          strokeWidth: 2.0,
                        ),
                        label: const Text(
                          'Directions',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          side: const BorderSide(color: AppColors.primary, width: 0.8),
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () {
                          if (property['propertyId'] == initialPropertyId) {
                            Navigator.of(context).pop();
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PropertyDetailScreen(
                                property: property,
                                isGuest: isGuest,
                                homeCubit: homeCubit,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'View details',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Outside-top start-aligned white pill badge for distance (floating with breathing room above card)
        if (dist != null)
          Positioned(
            top: -36,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.near_me_outlined,
                    size: 11.5,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${dist.toStringAsFixed(1)} km from destination',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SubtleTierColor {
  final Color bg;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;

  const _SubtleTierColor({
    required this.bg,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
  });

  static _SubtleTierColor forPercent(int percent) {
    if (percent >= 80) {
      return const _SubtleTierColor(
        bg: Color(0xFFF0FDF4),
        fillColor: Color(0xFF14B8A6), // Soft pastel teal/emerald
        borderColor: Color(0xFF86EFAC),
        textColor: Color(0xFF065F46),
      );
    } else if (percent >= 50) {
      return const _SubtleTierColor(
        bg: Color(0xFFFFFBEB),
        fillColor: Color(0xFFF59E0B), // Soft warm amber
        borderColor: Color(0xFFFDE68A),
        textColor: Color(0xFF92400E),
      );
    } else {
      return const _SubtleTierColor(
        bg: Color(0xFFF8FAFC),
        fillColor: Color(0xFF64748B), // Soft cool slate
        borderColor: Color(0xFFCBD5E1),
        textColor: Color(0xFF334155),
      );
    }
  }
}
