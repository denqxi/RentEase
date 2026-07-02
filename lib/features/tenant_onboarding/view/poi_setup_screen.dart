import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/widgets/form_step_layout.dart';
import '../../../features/registration/widgets/labeled_text_field.dart';
import '../../../features/registration/widgets/registration_app_bar.dart';
import '../../../shared/widgets/map_zoom_controls.dart';
import 'distance_preference_screen.dart';

class PoiSetupScreen extends StatefulWidget {
  const PoiSetupScreen({super.key});

  @override
  State<PoiSetupScreen> createState() => _PoiSetupScreenState();
}

class _PoiSetupScreenState extends State<PoiSetupScreen> {
  String _poiType = 'School';
  final _searchController = TextEditingController();
  final _mapController = MapController();
  String? _resolvedAddress;
  LatLng? _markerPos;
  List<Map<String, dynamic>> _suggestions = const [];

  bool get _hasMarker => _markerPos != null;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Mock reverse-geocode: label the tap with its nearest known area so the
  /// pill always matches the pinned spot. Production swaps in a real
  /// geocoding service.
  String _addressFor(LatLng pos) {
    Map<String, dynamic>? nearest;
    double best = double.infinity;
    for (final area in MockData.davaoAreas) {
      final dLat = pos.latitude - (area['lat'] as double);
      final dLng = pos.longitude - (area['lng'] as double);
      final d = dLat * dLat + dLng * dLng;
      if (d < best) {
        best = d;
        nearest = area;
      }
    }
    final coords = '${pos.latitude.toStringAsFixed(4)}, '
        '${pos.longitude.toStringAsFixed(4)}';
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
          : MockData.davaoPlaces
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
    // Defer the camera move until after the keyboard-dismiss relayout —
    // moving while the map is mid-rebuild leaves it blank.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(pos, 15);
    });
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DistancePreferenceScreen(
          poiName: _resolvedAddress ?? '$_poiType location',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
              ),
              child: RegistrationAppBar(
                onBack: () => Navigator.of(context).pop(),
                stepNumber: 3,
                stepCount: 5,
              ),
            ),
            Expanded(
              child: FormStepLayout(
                title: 'Where is your school\nor work?',
                subtitle: 'Tap the map to set your Point of Interest (POI).',
                buttonLabel: 'Confirm Location',
                onContinue: _hasMarker ? _continue : null,
                fields: [
                  _PoiTypeSelector(
                    selected: _poiType,
                    onSelected: (v) => setState(() => _poiType = v),
                  ),
                  LabeledTextField(
                    label: 'Search location',
                    hint: 'Search for your school or workplace...',
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  ),
                  if (_suggestions.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: context.appColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.field),
                        border:
                            Border.all(color: context.appColors.fieldBorder),
                      ),
                      child: Column(
                        children: [
                          for (final place in _suggestions)
                            ListTile(
                              dense: true,
                              leading: Icon(Icons.place_outlined,
                                  color: AppColors.accent, size: 18),
                              title: Text(
                                place['name'] as String,
                                style: AppTextStyles.caption(context).copyWith(
                                  color: context.appColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () => _selectPlace(place),
                            ),
                        ],
                      ),
                    ),
                  _PoiMap(
                    mapController: _mapController,
                    markerPos: _markerPos,
                    onTap: _dropPin,
                    onPlaceTap: _selectPlace,
                    onLocate: () {
                      const pos = LatLng(
                        MockData.tenantPoiLat,
                        MockData.tenantPoiLng,
                      );
                      _dropPin(pos, label: MockData.tenantPoi);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _mapController.move(pos, 15);
                      });
                    },
                  ),
                  if (_resolvedAddress != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadii.field),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              color: AppColors.accent, size: 16),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _resolvedAddress!,
                              style: AppTextStyles.caption(context)
                                  .copyWith(color: context.appColors.textPrimary),
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
      ),
    );
  }
}

class _PoiTypeSelector extends StatelessWidget {
  const _PoiTypeSelector({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['School', 'Workplace', 'Other'].map((type) {
        final isSelected = selected == type;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => onSelected(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : context.appColors.fieldFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? AppColors.accent : context.appColors.fieldBorder,
                ),
              ),
              child: Text(
                type,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppColors.onInk
                      : context.appColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Leaflet-style OpenStreetMap (flutter_map) — tap anywhere to drop the POI
/// pin, or use the locate button to jump to the demo POI.
class _PoiMap extends StatelessWidget {
  const _PoiMap({
    required this.mapController,
    required this.markerPos,
    required this.onTap,
    required this.onPlaceTap,
    required this.onLocate,
  });

  final MapController mapController;
  final LatLng? markerPos;
  final ValueChanged<LatLng> onTap;
  final ValueChanged<Map<String, dynamic>> onPlaceTap;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: context.appColors.fieldBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: const LatLng(
                MockData.tenantPoiLat,
                MockData.tenantPoiLng,
              ),
              initialZoom: 14,
              onTap: (_, latLng) => onTap(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rentease.app',
              ),
              MarkerLayer(
                markers: [
                  // Known schools and workplaces — tappable landmarks.
                  for (final place in MockData.davaoPlaces)
                    Marker(
                      point: LatLng(
                        place['lat'] as double,
                        place['lng'] as double,
                      ),
                      width: 30,
                      height: 30,
                      child: GestureDetector(
                        onTap: () => onPlaceTap(place),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.appColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accent),
                          ),
                          child: Icon(
                            place['type'] == 'school'
                                ? Icons.school_rounded
                                : Icons.work_rounded,
                            color: AppColors.accent,
                            size: 15,
                          ),
                        ),
                      ),
                    ),
                  // Tenant's chosen POI pin — drawn last so it sits on top.
                  if (markerPos != null)
                    Marker(
                      point: markerPos!,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: Icon(Icons.location_pin,
                          color: AppColors.accent, size: 40),
                    ),
                ],
              ),
            ],
          ),
          MapZoomControls(controller: mapController),
          if (markerPos == null)
            Positioned(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  border: Border.all(color: context.appColors.fieldBorder),
                ),
                child: Text(
                  'Tap the map to set your location',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ),
            ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Container(
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.field),
                border: Border.all(color: context.appColors.fieldBorder),
              ),
              child: IconButton(
                icon: Icon(Icons.my_location_rounded,
                    color: AppColors.accent, size: 20),
                onPressed: onLocate,
                padding: const EdgeInsets.all(AppSpacing.sm),
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
