import 'dart:async';
import 'dart:math' as math;
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
import '../../../core/utils/location_permission_helper.dart';
import '../widgets/live_user_puck.dart';
import 'property_detail_screen.dart';

// Compiled once instead of on every call.
final RegExp _kThousandsRe = RegExp(r'(\d)(?=(\d{3})+(?!\d))');

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

class _MapCluster {
  _MapCluster({
    required this.key,
    required this.point,
    required this.properties,
  });

  final String key;
  final LatLng point;
  final List<Map<String, dynamic>> properties;

  bool get isMultiRoom => properties.length > 1;
  Map<String, dynamic> get topProperty => properties.first;
}

int _compareListings(Map<String, dynamic> a, Map<String, dynamic> b) {
  final bool aNonMatch = (a['isNonMatch'] == true) || (a['bScore'] == 0);
  final bool bNonMatch = (b['isNonMatch'] == true) || (b['bScore'] == 0);
  if (aNonMatch != bNonMatch) {
    return aNonMatch ? 1 : -1;
  }
  final double aCi =
      aNonMatch ? 0.0 : ((a['tenantCi'] as num?)?.toDouble() ?? 0.0);
  final double bCi =
      bNonMatch ? 0.0 : ((b['tenantCi'] as num?)?.toDouble() ?? 0.0);
  final int ciCmp = bCi.compareTo(aCi);
  if (ciCmp != 0) return ciCmp;

  final int aRent = (a['monthlyRent'] as num?)?.toInt() ?? 0;
  final int bRent = (b['monthlyRent'] as num?)?.toInt() ?? 0;
  final int rentCmp = aRent.compareTo(bRent);
  if (rentCmp != 0) return rentCmp;

  final String aTitle = (a['title'] as String?) ?? '';
  final String bTitle = (b['title'] as String?) ?? '';
  return aTitle.compareTo(bTitle);
}

List<_MapCluster> _buildClusters(List<Map<String, dynamic>> properties) {
  final Map<String, List<Map<String, dynamic>>> groups = {};

  for (final p in properties) {
    final lat = (p['latitude'] as num?)?.toDouble();
    final lng = (p['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
      continue;
    }

    final parentId = (p['parentPropertyId'] as String?)?.trim();
    final coordKey = '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}';
    final groupKey = (parentId != null && parentId.isNotEmpty)
        ? 'parent_$parentId'
        : 'coord_$coordKey';

    groups.putIfAbsent(groupKey, () => []).add(p);
  }

  final List<_MapCluster> clusters = [];
  for (final entry in groups.entries) {
    final list = entry.value;
    list.sort(_compareListings);
    final top = list.first;
    final lat = (top['latitude'] as num).toDouble();
    final lng = (top['longitude'] as num).toDouble();
    clusters.add(
      _MapCluster(
        key: entry.key,
        point: LatLng(lat, lng),
        properties: list,
      ),
    );
  }

  // Draw lower-match pins first and higher-match pins on top
  clusters.sort((a, b) => _compareListings(b.topProperty, a.topProperty));

  return clusters;
}

class _MapViewScreenState extends State<MapViewScreen> {
  final _mapController = MapController();
  List<_MapCluster> _clusters = [];
  int? _selectedClusterIndex;
  int _selectedRoomIndex = 0;
  Map<String, dynamic>? _lastSelectedProperty;

  // ── Live Navigation State ──────────────────────────────────────────────────
  final _navigationService = NavigationService();
  bool _isNavigating = false;
  bool _isLocatingUser = false;
  bool _isLoadingRoute = false;
  RoutePlan? _currentRoutePlan;
  RouteProfile _currentProfile = RouteProfile.driving;
  LatLng? _userLocation;
  double _currentRotation = 0.0;
  double? _userHeading;
  StreamSubscription<Position>? _positionSubscription;
  bool _isCameraTrackingUser = true;

  // In-memory route plan cache keyed by "originLat,originLng_destLat,destLng_profile"
  final Map<String, RoutePlan> _routePlanCache = {};

  @override
  void initState() {
    super.initState();
    _clusters = _buildClusters(widget.properties);
    if (widget.isSinglePropertyMode && _clusters.isNotEmpty) {
      _selectedClusterIndex = 0;
      _selectedRoomIndex = 0;
      _lastSelectedProperty = _clusters.first.properties.first;
    } else if (widget.initialPropertyId != null) {
      for (int ci = 0; ci < _clusters.length; ci++) {
        final ri = _clusters[ci].properties.indexWhere(
          (p) => p['propertyId'] == widget.initialPropertyId,
        );
        if (ri != -1) {
          _selectedClusterIndex = ci;
          _selectedRoomIndex = ri;
          _lastSelectedProperty = _clusters[ci].properties[ri];
          break;
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant MapViewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.properties != oldWidget.properties) {
      _clusters = _buildClusters(widget.properties);
      if (_selectedClusterIndex != null &&
          _selectedClusterIndex! >= _clusters.length) {
        _selectedClusterIndex = null;
        _selectedRoomIndex = 0;
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

  Future<void> _handleMyLocationPressed() async {
    if (_isLocatingUser) return;
    setState(() => _isLocatingUser = true);
    try {
      final loc = await LocationPermissionHelper.getCurrentLocation(
        context,
        customPurposeMessage:
            'RentEase needs your location to pinpoint where you are on the map and find properties near you.',
      );
      if (loc != null && mounted) {
        setState(() {
          _userLocation = loc;
        });
        _mapController.move(loc, 16.0);
      }
    } finally {
      if (mounted) {
        setState(() => _isLocatingUser = false);
      }
    }
  }

  LatLng _resolveInitialCenter() {
    if (_selectedClusterIndex != null &&
        _selectedClusterIndex! < _clusters.length) {
      final cluster = _clusters[_selectedClusterIndex!];
      return LatLng(cluster.point.latitude - 0.0035, cluster.point.longitude);
    }
    return widget.poi ??
        const LatLng(
          AppOptions.defaultMapLat,
          AppOptions.defaultMapLng,
        );
  }

  void _onClusterTapped(int index, {int roomIndex = 0}) {
    if (index >= 0 && index < _clusters.length) {
      final cluster = _clusters[index];
      final safeRoomIndex = roomIndex.clamp(0, cluster.properties.length - 1);
      final p = cluster.properties[safeRoomIndex];
      setState(() {
        _selectedClusterIndex = index;
        _selectedRoomIndex = safeRoomIndex;
        _lastSelectedProperty = p;
      });

      final lat = cluster.point.latitude;
      final lng = cluster.point.longitude;
      if (lat != 0.0 && lng != 0.0) {
        // Offset southward slightly so the pin stays visible above the bottom preview card.
        _mapController.move(LatLng(lat - 0.0035, lng), 15.5);
      }
    }
  }

  void _dismissSelection() {
    if (widget.isSinglePropertyMode) return;
    if (_selectedClusterIndex != null) {
      setState(() {
        _selectedClusterIndex = null;
        _selectedRoomIndex = 0;
      });
    }
  }

  void _openNearbyPropertiesSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) => _NearbyPropertiesSheet(
        properties: widget.properties,
        poiLabel: widget.poiLabel,
        poiType: widget.poiType,
        isGuest: widget.isGuest,
        onSelectProperty: (property) {
          Navigator.of(sheetContext).pop();
          for (int ci = 0; ci < _clusters.length; ci++) {
            final ri = _clusters[ci].properties.indexWhere(
              (p) => p['propertyId'] == property['propertyId'],
            );
            if (ri != -1) {
              _onClusterTapped(ci, roomIndex: ri);
              break;
            }
          }
        },
      ),
    );
  }

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(_kThousandsRe, (m) => '${m[1]},');

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
    final selectedCluster = _selectedClusterIndex != null &&
            _selectedClusterIndex! < _clusters.length
        ? _clusters[_selectedClusterIndex!]
        : null;
    final activeProperty = selectedCluster != null
        ? selectedCluster.properties[_selectedRoomIndex.clamp(
            0,
            selectedCluster.properties.length - 1,
          )]
        : _lastSelectedProperty;

    return PopScope(
      canPop: !_isNavigating,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isNavigating) {
          _exitNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: context.appColors.fieldFill,
        body: Stack(
          children: [
            // ── Edge-to-Edge Interactive Map with Google Maps Light Filter ──
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _resolveInitialCenter(),
                  initialZoom: _selectedClusterIndex != null ? 15.5 : 13.5,
                  // Tapping empty map space dismisses selected property card.
                  onTap: (_, _) => _dismissSelection(),
                  onPositionChanged: (camera, hasGesture) {
                    if ((camera.rotation - _currentRotation).abs() > 0.4) {
                      setState(() {
                        _currentRotation = camera.rotation;
                      });
                    }
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
                          color: AppColors.primaryDeep,
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                        ),
                        // Inner route polyline (vibrant Google Maps navigation blue)
                        Polyline(
                          points: _currentRoutePlan!.points,
                          strokeWidth: 5.0,
                          color: AppColors.blue600,
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                        ),
                      ],
                    ),

                  MarkerLayer(
                    rotate: true,
                    alignment: Alignment.topCenter,
                    markers: [
                      // Tenant POI marker — exactly anchored to widget.poi at the badge center!
                      if (widget.poi != null &&
                          !(widget.isSinglePropertyMode &&
                              properties.isNotEmpty &&
                              (widget.poi!.latitude - (properties.first['latitude'] as num).toDouble()).abs() < 0.0001 &&
                              (widget.poi!.longitude - (properties.first['longitude'] as num).toDouble()).abs() < 0.0001))
                        Marker(
                          point: widget.poi!,
                          width: 280,
                          height: 94,
                          alignment: Marker.computePixelAlignment(
                            width: 280,
                            height: 94,
                            left: 140,
                            top: 72,
                          ),
                          rotate: true,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Destination Label Card with Icon and Subtitle
                                Container(
                                  margin: const EdgeInsets.only(bottom: 3),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  constraints: const BoxConstraints(maxWidth: 250),
                                  decoration: BoxDecoration(
                                    color: context.appColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.blue600.withValues(alpha: 0.4),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.blue600.withValues(alpha: 0.16),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 3),
                                      ),
                                      BoxShadow(
                                        color: AppColors.scrim.withValues(alpha: 0.10),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1.5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Soft blue circular container with original destination icon
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: const BoxDecoration(
                                          color: AppColors.skyFill,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _resolvePoiIcon(),
                                            size: 14,
                                            color: AppColors.blue600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

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
                                              style: TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: context.appColors.textPrimary,
                                                letterSpacing: -0.1,
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              'Davao City',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                                color: context.appColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Connecting dot directly below card
                                Container(
                                  width: 5.5,
                                  height: 5.5,
                                  margin: const EdgeInsets.only(bottom: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.blue600,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.scrim.withValues(alpha: 0.2),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),

                                // Concentric rings with circular badge anchored to coordinates
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer subtle ring
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.blue600.withValues(alpha: 0.16),
                                        ),
                                      ),
                                      // Middle subtle ring
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.blue600.withValues(alpha: 0.28),
                                        ),
                                      ),
                                      // Core solid blue circular badge with white outline
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: AppColors.blue600,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.blue600.withValues(alpha: 0.45),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _resolvePoiIcon(),
                                            color: Colors.white,
                                            size: 14,
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

                      // Unselected property markers — bottom tip planted exactly on coordinates
                      for (int i = 0; i < _clusters.length; i++)
                        if (i != _selectedClusterIndex)
                          Marker(
                            point: _clusters[i].point,
                            width: 96,
                            height: 76,
                            alignment: Alignment.topCenter,
                            rotate: true,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _PropertyPinMarker(
                                property: _clusters[i].topProperty,
                                roomCount: _clusters[i].properties.length,
                                isSelected: false,
                                onTap: () => _onClusterTapped(i),
                              ),
                            ),
                          ),

                      // Selected property marker rendered LAST so it sits on top with halo
                      if (_selectedClusterIndex != null &&
                          _selectedClusterIndex! < _clusters.length)
                        Marker(
                          point: _clusters[_selectedClusterIndex!].point,
                          width: 104,
                          height: 86,
                          alignment: Alignment.topCenter,
                          rotate: true,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _PropertyPinMarker(
                              property: _clusters[_selectedClusterIndex!].properties[
                                  _selectedRoomIndex.clamp(
                                      0,
                                      _clusters[_selectedClusterIndex!]
                                              .properties
                                              .length -
                                          1)],
                              roomCount: _clusters[_selectedClusterIndex!]
                                  .properties
                                  .length,
                              isSelected: true,
                              onTap: () =>
                                  _onClusterTapped(_selectedClusterIndex!),
                            ),
                          ),
                        ),

                      // Live Location Puck with Heading Cone
                      if (_userLocation != null)
                        Marker(
                          point: _userLocation!,
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          rotate: false,
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
                  color: AppColors.transparent,
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
                        color: context.appColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.scrim.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: context.appColors.textPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isNavigating ? 'Route preview' : 'Map view',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: context.appColors.textPrimary,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                  // Current Location Button (requests GPS & centers live user location)
                  Material(
                    color: AppColors.transparent,
                    child: InkWell(
                      onTap: _handleMyLocationPressed,
                      borderRadius: BorderRadius.circular(19),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: context.appColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.scrim.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isLocatingUser
                            ? const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.blue600,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.my_location_rounded,
                                size: 18,
                                color: AppColors.blue600,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Google Maps Compass (only visible when map is rotated) ───────
          if (_currentRotation.abs() > 0.8)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height * 0.42 - 42,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.scrim.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: AppColors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      _mapController.rotate(0);
                      setState(() {
                        _currentRotation = 0.0;
                      });
                    },
                    child: Transform.rotate(
                      angle: -_currentRotation * (math.pi / 180.0),
                      child: const Center(
                        child: CustomPaint(
                          size: Size(14, 20),
                          painter: _CompassNeedlePainter(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Zoom Controls (Clean minimal pill on the right side) ─────────
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.42,
            child: Container(
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.scrim.withValues(alpha: 0.08),
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
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(Icons.add_rounded, size: 18, color: context.appColors.textPrimary),
                    ),
                  ),
                  Divider(height: 1, thickness: 0.8, color: context.appColors.fieldBorder),
                  InkWell(
                    onTap: () {
                      final camera = _mapController.camera;
                      _mapController.move(camera.center, camera.zoom - 1);
                    },
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(Icons.remove_rounded, size: 18, color: context.appColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Screen 1: Clean, Compact Bottom Button ───────────────────────
          if (!_isNavigating && !widget.isSinglePropertyMode && _selectedClusterIndex == null)
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
                    color: context.appColors.surface,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.scrim.withValues(alpha: 0.12),
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
                        color: AppColors.sky400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Properties near your destination',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.appColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Screen 3: Selected Property Preview Bottom Card ───────────────
          if (!_isNavigating && selectedCluster != null && activeProperty != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _PropertyPreviewBottomCard(
                property: activeProperty,
                clusterProperties: selectedCluster.isMultiRoom
                    ? selectedCluster.properties
                    : null,
                selectedRoomIndex: _selectedRoomIndex,
                onRoomSelected: (idx) {
                  setState(() {
                    _selectedRoomIndex = idx;
                    _lastSelectedProperty = selectedCluster.properties[idx];
                  });
                },
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
                color: context.appColors.surface,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                shadowColor: AppColors.scrim.withValues(alpha: 0.15),
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
                    child: Icon(
                      Icons.crop_free_rounded,
                      size: 20,
                      color: context.appColors.textPrimary,
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
                destinationName: (activeProperty?['propertyName'] as String?) != null &&
                        (activeProperty?['roomName'] as String?)?.trim().isNotEmpty == true
                    ? '${activeProperty!['propertyName']} — ${activeProperty['roomName']}'
                    : (activeProperty?['propertyName'] as String?) ??
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
    this.roomCount = 1,
  });

  final Map<String, dynamic> property;
  final bool isSelected;
  final VoidCallback onTap;
  final int roomCount;

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
    final bool isNonMatch = (widget.property['isNonMatch'] == true) ||
        (widget.property['bScore'] == 0);
    final double ci = isNonMatch ? 0.0 : ((widget.property['tenantCi'] as num?)?.toDouble() ?? 0.0);
    final int percent = (ci * 100).round();
    final tier = _SubtleTierColor.forPercent(percent, isNonMatch: isNonMatch);

    final double pinW = widget.isSelected ? 32.0 : 26.0;
    final double pinH = widget.isSelected ? 44.0 : 36.0;
    final double iconSize = widget.isSelected ? 19.0 : 15.5;

    final bool isGray = isNonMatch || percent <= 0;
    final Color themeColor = isGray ? context.appColors.hint : AppColors.sky400;

    final Color pinFillColor = widget.isSelected ? themeColor : context.appColors.surface;
    final Color pinStrokeColor = widget.isSelected ? context.appColors.surface : themeColor;
    final Color pinIconColor = widget.isSelected ? context.appColors.surface : themeColor;
    final double pinStrokeWidth = widget.isSelected ? 1.5 : 1.2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Animated Pulse Effect when selected (centered on needle tip)
          if (widget.isSelected)
            Positioned(
              bottom: -16,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _pulseScaleAnimation.value,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeColor.withValues(
                            alpha: _pulseOpacityAnimation.value,
                          ),
                          border: Border.all(
                            color: themeColor.withValues(
                              alpha: _pulseOpacityAnimation.value * 0.9,
                            ),
                            width: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Secondary subtle inner glow ring (centered on needle tip)
          if (widget.isSelected)
            Positioned(
              bottom: -13,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeColor.withValues(alpha: 0.25),
                ),
              ),
            ),

          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Percentage / Status Capsule with glow & shadow
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.8),
                decoration: BoxDecoration(
                  color: tier.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tier.borderColor,
                    width: 0.9,
                  ),
                  boxShadow: [
                    // Glow halo matching tier
                    BoxShadow(
                      color: tier.borderColor.withValues(alpha: 0.30),
                      blurRadius: 5,
                      spreadRadius: 0.5,
                    ),
                    // Grounding shadow
                    BoxShadow(
                      color: AppColors.scrim.withValues(alpha: 0.12),
                      blurRadius: 3,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isGray ? '0% Not Match' : '$percent%',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: widget.isSelected ? 10.5 : 10,
                        fontWeight: FontWeight.w700,
                        color: tier.textColor,
                      ),
                    ),
                    if (widget.roomCount > 1) ...[
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${widget.roomCount}',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 1.5),

              // Teardrop Pin with original colors + glowing halo & shadow
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
                          strokeWidth: pinStrokeWidth,
                          glowColor: themeColor,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 1.0,
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
  final Color glowColor;

  _TeardropPinPainter({
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 1.2,
    required this.glowColor,
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

    // 1. Soft atmospheric glow halo around the pin in the original theme color
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawPath(path, glowPaint);

    // 2. High-contrast ambient drop shadow to separate white pin from light map tiles
    final shadowPaint = Paint()
      ..color = AppColors.scrim.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2);
    canvas.drawPath(path.shift(const Offset(0, 2.2)), shadowPaint);

    // 3. Elevated ground shadow
    canvas.drawShadow(path, AppColors.scrim.withValues(alpha: 0.20), 3.0, false);

    // 4. Fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 5. Stroke Outline
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
      strokeWidth != oldDelegate.strokeWidth ||
      glowColor != oldDelegate.glowColor;
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
  // Default is Ci-ranked (CLAUDE.md rule 9); "nearest" is an explicit opt-in.
  _SortOption _sortBy = _SortOption.highestMatch;

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(_kThousandsRe, (m) => '${m[1]},');

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
    final sortedList = sortNearbyProperties(
      widget.properties,
      nearest: _sortBy == _SortOption.nearest,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: context.appColors.hint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: 16sp Semibold Section Heading & Count Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Properties near your destination',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: context.appColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: context.appColors.fieldFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.properties.length} nearby',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textSecondary,
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
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textSecondary,
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
                final bool isNonMatch = (property['isNonMatch'] == true) ||
                    (property['bScore'] == 0);
                final double ci = isNonMatch ? 0.0 : ((property['tenantCi'] as num?)?.toDouble() ?? 0.0);
                final int percent = (ci * 100).round();
                final tier = _SubtleTierColor.forPercent(percent, isNonMatch: isNonMatch);

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
                      color: context.appColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.appColors.fieldBorder, width: 0.8),
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
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.appColors.textPrimary,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Line 2: Room / Location (11.5sp, muted gray)
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: context.appColors.textSecondary,
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      propName != null
                                          ? roomOrTitle
                                          : ((property['address'] as String?) ?? 'Davao City'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: context.appColors.textSecondary,
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
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: context.appColors.textSecondary,
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
                                    TextSpan(
                                      text: ' / month',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w400,
                                        color: context.appColors.textSecondary,
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
                                border: Border.all(color: tier.borderColor, width: 1.0),
                              ),
                              child: Text(
                                (isNonMatch || percent <= 0) ? '0% Not Match' : '$percent%',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: tier.textColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: context.appColors.hint,
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
          color: isSelected ? AppColors.primary : context.appColors.fieldFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.surface : context.appColors.textSecondary,
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
    this.clusterProperties,
    this.selectedRoomIndex = 0,
    this.onRoomSelected,
  });

  final Map<String, dynamic> property;
  final bool isGuest;
  final HomeCubit? homeCubit;
  final String? initialPropertyId;
  final String Function(num) fmt;
  final LatLng? poi;
  final VoidCallback? onDirectionsTap;
  final List<Map<String, dynamic>>? clusterProperties;
  final int selectedRoomIndex;
  final ValueChanged<int>? onRoomSelected;

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
    // (0, 0) is the models' "no pin" default: no bogus distance for it.
    if ((dist == null || dist == 0.0) && propLat != null && propLng != null &&
        !(propLat == 0 && propLng == 0) && poi != null) {
      dist = const Distance().as(LengthUnit.Kilometer, LatLng(propLat, propLng), poi);
    }
    final bool isNonMatch = (property['isNonMatch'] == true) ||
        (property['bScore'] == 0);
    final double ci = isNonMatch ? 0.0 : ((property['tenantCi'] as num?)?.toDouble() ?? 0.0);
    final int percent = (ci * 100).round();
    final tier = _SubtleTierColor.forPercent(percent, isNonMatch: isNonMatch);

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
            color: context.appColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                color: AppColors.scrim.withValues(alpha: 0.12),
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
                    color: context.appColors.hint,
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
                              color: AppColors.scrim.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '1/$photoCount',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.surface,
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
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.appColors.textPrimary,
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
                                border: Border.all(color: tier.borderColor, width: 1.0),
                              ),
                              child: Text(
                                (isNonMatch || percent <= 0) ? '0% Not Match' : '$percent%',
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
                              Padding(
                                padding: const EdgeInsets.only(top: 1.5),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: context.appColors.textSecondary,
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
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: context.appColors.textSecondary,
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
                              TextSpan(
                                text: ' / month',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                  color: context.appColors.textSecondary,
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
              // Available Rooms Selector (When multiple rooms exist at this location)
              if (widget.clusterProperties != null &&
                  widget.clusterProperties!.length > 1) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.meeting_room_outlined,
                      size: 13,
                      color: context.appColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Available Rooms (${widget.clusterProperties!.length})',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Tap to switch room',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.clusterProperties!.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final room = widget.clusterProperties![i];
                      final isSelected = i == widget.selectedRoomIndex;
                      final (rProp, rRoom) = ListingCardLarge.resolveTitles(
                        rawTitle: (room['title'] as String?) ?? 'Room',
                        explicitPropertyName: room['propertyName'] as String?,
                        explicitRoomName: room['roomName'] as String?,
                      );
                      final bool rIsNonMatch =
                          (room['isNonMatch'] == true) || (room['bScore'] == 0);
                      final double rCi = rIsNonMatch
                          ? 0.0
                          : ((room['tenantCi'] as num?)?.toDouble() ?? 0.0);
                      final int rPercent = (rCi * 100).round();
                      final rTier = _SubtleTierColor.forPercent(
                        rPercent,
                        isNonMatch: rIsNonMatch,
                      );
                      final rRent =
                          (room['monthlyRent'] as num?)?.round() ?? 0;

                      return Material(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : context.appColors.fieldFill,
                        borderRadius: BorderRadius.circular(9),
                        child: InkWell(
                          onTap: () => widget.onRoomSelected?.call(i),
                          borderRadius: BorderRadius.circular(9),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : context.appColors.fieldBorder,
                                width: isSelected ? 1.4 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  rRoom,
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : context.appColors.textPrimary,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: rTier.bg,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: rTier.borderColor,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    (rIsNonMatch || rPercent <= 0)
                                        ? '0% Not Match'
                                        : '$rPercent%',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: rTier.textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '₱${fmt(rRent)}',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: context.appColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
                        label: Text(
                          widget.clusterProperties != null &&
                                  widget.clusterProperties!.length > 1
                              ? 'Directions ($roomOrTitle)'
                              : 'Directions',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          side: const BorderSide(color: AppColors.primary, width: 0.8),
                          backgroundColor: context.appColors.surface,
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
                          foregroundColor: AppColors.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          widget.clusterProperties != null &&
                                  widget.clusterProperties!.length > 1
                              ? 'View $roomOrTitle'
                              : 'View details',
                          style: const TextStyle(
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
                color: context.appColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.appColors.fieldBorder,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.scrim.withValues(alpha: 0.08),
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
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
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

  static _SubtleTierColor forPercent(int percent, {bool isNonMatch = false}) {
    if (isNonMatch || percent <= 0) {
      return const _SubtleTierColor(
        bg: AppColors.fieldFill,
        fillColor: AppColors.slate400, // Neutral gray for 0% / incompatible
        borderColor: AppColors.slate300,
        textColor: AppColors.slate500,
      );
    } else if (percent >= 80) {
      return const _SubtleTierColor(
        bg: AppColors.greenFill,
        fillColor: AppColors.primaryTeal, // Soft pastel teal/emerald
        borderColor: AppColors.emerald400,
        textColor: AppColors.greenText,
      );
    } else if (percent >= 50) {
      return const _SubtleTierColor(
        bg: AppColors.amberFill50,
        fillColor: AppColors.matchMedium, // Soft warm amber
        borderColor: AppColors.amberBorder200,
        textColor: AppColors.amber800,
      );
    } else {
      return const _SubtleTierColor(
        bg: AppColors.slate50,
        fillColor: AppColors.slate500, // Soft cool slate
        borderColor: AppColors.slate300,
        textColor: AppColors.slate700,
      );
    }
  }
}

/// Sorts map-sheet properties. Default is highest match: [tenantCi]
/// descending (CLAUDE.md rule 9); [nearest] is an explicit opt-in.
List<Map<String, dynamic>> sortNearbyProperties(
  List<Map<String, dynamic>> properties, {
  bool nearest = false,
}) {
  final sorted = List<Map<String, dynamic>>.from(properties);
  if (nearest) {
    sorted.sort((a, b) {
      final distA = (a['distance'] as num?)?.toDouble() ?? 999.0;
      final distB = (b['distance'] as num?)?.toDouble() ?? 999.0;
      return distA.compareTo(distB);
    });
  } else {
    sorted.sort((a, b) {
      final ciA = (a['tenantCi'] as num?)?.toDouble() ?? 0.0;
      final ciB = (b['tenantCi'] as num?)?.toDouble() ?? 0.0;
      return ciB.compareTo(ciA);
    });
  }
  return sorted;
}

/// Google Maps-style North compass needle painter.
class _CompassNeedlePainter extends CustomPainter {
  const _CompassNeedlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final h = size.height;
    final w = size.width;

    // Top red needle (North)
    final northPath = Path()
      ..moveTo(cx, 0)
      ..lineTo(cx + w * 0.42, cy)
      ..lineTo(cx, cy - 1.5)
      ..lineTo(cx - w * 0.42, cy)
      ..close();

    final northPaint = Paint()
      ..color = AppColors.red600
      ..style = PaintingStyle.fill;
    canvas.drawPath(northPath, northPaint);

    // Bottom grey needle (South)
    final southPath = Path()
      ..moveTo(cx, h)
      ..lineTo(cx + w * 0.42, cy)
      ..lineTo(cx, cy + 1.5)
      ..lineTo(cx - w * 0.42, cy)
      ..close();

    final southPaint = Paint()
      ..color = AppColors.slate400
      ..style = PaintingStyle.fill;
    canvas.drawPath(southPath, southPaint);

    // Center pivot dot
    final pivotPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 1.8, pivotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
