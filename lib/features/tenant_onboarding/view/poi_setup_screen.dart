import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_options.dart';
import '../../../shared/widgets/map_zoom_controls.dart';
import '../cubit/tenant_onboarding_cubit.dart';
import 'topsis_weight_screen.dart';

/// Onboarding Step 3 — Destination & Travel Distance (Merged POI & Distance Step).
/// Captures the tenant's primary commute destination (school, workplace, or other)
/// and their maximum comfortable travel radius in a single screen.
class PoiSetupScreen extends StatefulWidget {
  const PoiSetupScreen({super.key});

  @override
  State<PoiSetupScreen> createState() => _PoiSetupScreenState();
}

class _PoiSetupScreenState extends State<PoiSetupScreen> {
  // Theme Color Tokens
  static const Color _primaryTeal = Color(0xFF149BBD);
  static const Color _midnightNavy = Color(0xFF1D1C2E);
  static const Color _surfaceTint = Color(0xFFEBF2F5);
  static const Color _borderStroke = Color(0xFFE2E8F0);
  static const Color _borderStrokeDark = Color(0xFFCBD5E1);
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  // Form State
  String _poiType = 'School'; // 'School', 'Workplace', 'Other'
  final _searchController = TextEditingController();
  final _mapController = MapController();
  String? _resolvedAddress;
  LatLng? _markerPos;
  List<Map<String, dynamic>> _suggestions = const [];
  double _maxKm = 3.0;

  // Map hint auto-hide after 15 seconds
  bool _showMapHint = true;
  Timer? _mapHintTimer;

  @override
  void initState() {
    super.initState();
    final cubitState = context.read<TenantOnboardingCubit>().state;

    // Restore previously saved state if available, or fall back to defaults
    if (cubitState.poiType.isNotEmpty) {
      _poiType = cubitState.poiType;
    }
    if (cubitState.poiLatLng != null) {
      _markerPos = LatLng(
        cubitState.poiLatLng!.latitude,
        cubitState.poiLatLng!.longitude,
      );
      _resolvedAddress = cubitState.poiLabel ?? AppOptions.defaultMapLabel;
    } else {
      _markerPos = const LatLng(
        AppOptions.defaultMapLat,
        AppOptions.defaultMapLng,
      );
      _resolvedAddress = AppOptions.defaultMapLabel;
    }

    if (cubitState.maxDistanceKm > 0) {
      _maxKm = cubitState.maxDistanceKm;
    }

    // Dismiss map hint overlay automatically after 15 seconds
    _mapHintTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() => _showMapHint = false);
      }
    });
  }

  @override
  void dispose() {
    _mapHintTimer?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Reverse-geocode lookup based on Davao City reference areas.
  String _addressFor(LatLng pos) {
    Map<String, dynamic>? nearest;
    double best = double.infinity;
    for (final area in AppOptions.davaoAreas) {
      final dLat = pos.latitude - (area['lat'] as double);
      final dLng = pos.longitude - (area['lng'] as double);
      final d = dLat * dLat + dLng * dLng;
      if (d < best) {
        best = d;
        nearest = area;
      }
    }
    final coords =
        '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
    return 'Near ${nearest!['name']}, Davao City ($coords)';
  }

  void _dropPin(LatLng position, {String? label}) {
    setState(() {
      _markerPos = position;
      _resolvedAddress = label ?? _addressFor(position);
    });
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _suggestions = q.length < 2
          ? const []
          : AppOptions.davaoPlaces
              .where((p) => (p['name'] as String).toLowerCase().contains(q))
              .toList();
    });
  }

  void _selectPlace(Map<String, dynamic> place) {
    final pos = LatLng(place['lat'] as double, place['lng'] as double);
    _searchController.text = place['name'] as String;
    setState(() => _suggestions = const []);
    FocusScope.of(context).unfocus();
    _dropPin(pos, label: '${place['name']}, Davao City');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(pos, 14.5);
    });
  }

  void _recenterDefault() {
    final pos = _markerPos ??
        const LatLng(
          AppOptions.defaultMapLat,
          AppOptions.defaultMapLng,
        );
    _dropPin(pos, label: _resolvedAddress ?? AppOptions.defaultMapLabel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(pos, 14.5);
    });
  }

  void _continue() {
    final pos = _markerPos ??
        const LatLng(
          AppOptions.defaultMapLat,
          AppOptions.defaultMapLng,
        );
    final label = _resolvedAddress ?? '$_poiType location';

    // Single unified submit to Cubit
    context.read<TenantOnboardingCubit>().savePoi(
      poiType: _poiType,
      latitude: pos.latitude,
      longitude: pos.longitude,
      label: label,
    );
    context.read<TenantOnboardingCubit>().saveMaxDistance(_maxKm);

    // Proceed to Step 4 (TOPSIS weights)
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TopsisWeightScreen(),
      ),
    );
  }

  // Dynamic Search Field Properties based on Active Purpose
  String get _searchLabel {
    switch (_poiType) {
      case 'Workplace':
        return 'YOUR WORKPLACE OR OFFICE';
      case 'Other':
        return 'YOUR MAIN DESTINATION';
      case 'School':
      default:
        return 'YOUR SCHOOL OR CAMPUS';
    }
  }

  String get _searchPlaceholder {
    switch (_poiType) {
      case 'Workplace':
        return 'Search company, building, or office park...';
      case 'Other':
        return 'Search hospital, landmark, or terminal...';
      case 'School':
      default:
        return 'Search university or campus (e.g., ADDU, USeP)...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Back button, Progress bar (3 / 4), Step indicator
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.appColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _borderStroke,
                        ),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: _textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 3 / 4,
                        minHeight: 5,
                        backgroundColor: context.appColors.indicatorInactive
                            .withValues(alpha: 0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _primaryTeal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    '3 / 4',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // A. Header
                      const Text(
                        'Where do you commute to daily?',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _midnightNavy,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Set your school or workplace so we can show rentals within your travel range.',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: _textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // B. Purpose / Category Selection (smaller, compact height)
                      const Text(
                        'I AM COMMUTING TO',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _CategoryCard(
                              label: 'School',
                              iconPath: 'assets/images/school.png',
                              isActive: _poiType == 'School',
                              onTap: () => setState(() => _poiType = 'School'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CategoryCard(
                              label: 'Work',
                              iconPath: 'assets/images/work.png',
                              isActive: _poiType == 'Workplace',
                              onTap: () =>
                                  setState(() => _poiType = 'Workplace'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CategoryCard(
                              label: 'Personal',
                              iconPath: 'assets/images/personal.png',
                              isActive: _poiType == 'Other',
                              onTap: () => setState(() => _poiType = 'Other'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // C. Search Bar & Destination Input (compact height & smaller secondary label)
                      Text(
                        _searchLabel,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: _textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: _searchPlaceholder,
                          hintStyle: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12.5,
                            color: _textSecondary,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: _textSecondary,
                            size: 18,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: _textSecondary,
                                  ),
                                )
                              : null,
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _borderStroke,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _primaryTeal,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      // Search Suggestions Popup List
                      if (_suggestions.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: context.appColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _borderStroke),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              for (final place in _suggestions)
                                ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.location_on_outlined,
                                    color: _primaryTeal,
                                    size: 18,
                                  ),
                                  title: Text(
                                    place['name'] as String,
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  onTap: () => _selectPlace(place),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // D. Map View with accurate geographic distance radius
                      Container(
                        height: 210,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderStroke),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _markerPos ??
                                    const LatLng(
                                      AppOptions.defaultMapLat,
                                      AppOptions.defaultMapLng,
                                    ),
                                initialZoom: 13.5,
                                onTap: (_, latLng) => _dropPin(latLng),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.rentease.app',
                                ),
                                // Accurate geographic radius circle overlay
                                if (_markerPos != null)
                                  CircleLayer(
                                    circles: [
                                      CircleMarker(
                                        point: _markerPos!,
                                        radius: _maxKm * 1000,
                                        useRadiusInMeter: true,
                                        color: _primaryTeal.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderColor: _primaryTeal,
                                        borderStrokeWidth: 1.5,
                                      ),
                                    ],
                                  ),
                                MarkerLayer(
                                  markers: [
                                    // Known school and workplace landmarks
                                    for (final place in AppOptions.davaoPlaces)
                                      Marker(
                                        point: LatLng(
                                          place['lat'] as double,
                                          place['lng'] as double,
                                        ),
                                        width: 26,
                                        height: 26,
                                        child: GestureDetector(
                                          onTap: () => _selectPlace(place),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: _primaryTeal,
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.1),
                                                  blurRadius: 3,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              place['type'] == 'school'
                                                  ? Icons.school_rounded
                                                  : Icons.work_rounded,
                                              color: _primaryTeal,
                                              size: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Main chosen POI pin
                                    if (_markerPos != null)
                                      Marker(
                                        point: _markerPos!,
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.topCenter,
                                        child: const Icon(
                                          Icons.location_pin,
                                          color: _primaryTeal,
                                          size: 40,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            MapZoomControls(controller: _mapController),
                            // GPS Recenter Button
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _borderStroke),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.my_location_rounded,
                                    color: _primaryTeal,
                                    size: 18,
                                  ),
                                  onPressed: _recenterDefault,
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(
                                    minWidth: 34,
                                    minHeight: 34,
                                  ),
                                ),
                              ),
                            ),
                            // Map Hint Overlay inside Map (auto-hides after 15 seconds)
                            if (_showMapHint)
                              Positioned(
                                left: 8,
                                bottom: 8,
                                child: AnimatedOpacity(
                                  opacity: _showMapHint ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.92),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: _borderStroke),
                                    ),
                                    child: const Text(
                                      '💡 Tap map or drag pin to your exact building or gate',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Selected Destination Card (compact height & unbolded label)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _surfaceTint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _borderStrokeDark),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _primaryTeal.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: _primaryTeal,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DESTINATION POINT:',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 10,
                                      fontWeight: FontWeight.normal, // Unbolded
                                      letterSpacing: 0.6,
                                      color: _primaryTeal,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    _resolvedAddress ??
                                        'Tap the map or search to choose destination',
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // E. Distance Slider Section (compact & smaller labels)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'MAXIMUM TRAVEL DISTANCE',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: _textSecondary,
                            ),
                          ),
                          Text(
                            'Up to ${_maxKm.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _primaryTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackShape: const _FullWidthSliderTrackShape(),
                          activeTrackColor: _primaryTeal,
                          inactiveTrackColor: _borderStroke,
                          thumbColor: _primaryTeal,
                          overlayColor: _primaryTeal.withValues(alpha: 0.15),
                          trackHeight: 3.5,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                        ),
                        child: Slider(
                          value: _maxKm,
                          min: 1.0,
                          max: 10.0,
                          divisions: 18,
                          onChanged: (v) => setState(() => _maxKm = v),
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Commute Explainer Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _surfaceTint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _borderStrokeDark),
                        ),
                        child: Text(
                          'Rentals within ${_maxKm.toStringAsFixed(1)} km of your destination will be prioritized.',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: _textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // F. Bottom CTA Button
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(_midnightNavy),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                    elevation: WidgetStateProperty.all(0),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Save and Continue',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category box card widget for purpose selection (School, Work, Personal).
/// Compact dimensions and icon sizes to conserve screen space.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.iconPath,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final bool isActive;
  final VoidCallback onTap;

  static const Color _primaryTeal = Color(0xFF149BBD);
  static const Color _surfaceTint = Color(0xFFEBF2F5);
  static const Color _borderStroke = Color(0xFFE2E8F0);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isActive ? _surfaceTint : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _primaryTeal : _borderStroke,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
              errorBuilder: (_, _, _) => const Icon(
                Icons.location_city_rounded,
                size: 22,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? _primaryTeal : _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom slider track shape that expands the track to the full width of the parent.
class _FullWidthSliderTrackShape extends RoundedRectSliderTrackShape {
  const _FullWidthSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 3.5;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(
      offset.dx,
      trackTop,
      parentBox.size.width,
      trackHeight,
    );
  }
}
