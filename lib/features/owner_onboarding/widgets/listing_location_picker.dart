import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_options.dart';
import '../../../core/utils/location_permission_helper.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/map_zoom_controls.dart';

/// Address field + tap-to-pin OpenStreetMap picker. This is the same map,
/// geocoding and styling that `AddPropertyScreen` used, extracted so the
/// wizard (Step 2) and the "Add New Property" sheet share it unchanged.
class ListingLocationPicker extends StatefulWidget {
  const ListingLocationPicker({
    required this.addressController,
    required this.pin,
    required this.onPinChanged,
    required this.onChanged,
    super.key,
  });

  final TextEditingController addressController;
  final LatLng? pin;

  /// Called when the owner taps the map.
  final ValueChanged<LatLng> onPinChanged;

  /// Called when the address text or resolving state changes so the parent
  /// can re-evaluate its Continue/Save button.
  final ValueChanged<bool> onChanged;

  @override
  State<ListingLocationPicker> createState() => _ListingLocationPickerState();
}

class _ListingLocationPickerState extends State<ListingLocationPicker> {
  final _mapController = MapController();
  final _geocodingService = const GeocodingService();
  bool _isResolvingAddress = false;
  bool _isLocatingCurrent = false;
  int _geocodeRequestId = 0;

  LatLng? get _pinnedLocation => widget.pin;

  Future<void> _onMapTapped(LatLng latLng) async {
    final requestId = ++_geocodeRequestId;
    widget.onPinChanged(latLng);
    setState(() => _isResolvingAddress = true);
    widget.onChanged(true);

    try {
      final address = await _geocodingService.reverseGeocode(
        latLng.latitude,
        latLng.longitude,
      );

      if (requestId != _geocodeRequestId || !mounted) return;

      setState(() {
        widget.addressController.text = address;
        _isResolvingAddress = false;
      });
      widget.onChanged(false);
    } catch (_) {
      if (requestId != _geocodeRequestId || !mounted) return;
      setState(() => _isResolvingAddress = false);
      widget.onChanged(false);
    }
  }

  Future<void> _locateCurrentPosition() async {
    if (_isLocatingCurrent) return;
    setState(() => _isLocatingCurrent = true);

    try {
      final latLng = await LocationPermissionHelper.getCurrentLocation(
        context,
        customPurposeMessage:
            'RentEase needs location access to pinpoint your property on the map. You can also tap directly on the map to set your pin.',
      );
      if (latLng != null && mounted) {
        _mapController.move(latLng, 16);
        await _onMapTapped(latLng);
      }
    } finally {
      if (mounted) setState(() => _isLocatingCurrent = false);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelledField(
          label: 'Full address',
          child: AppTextField(
            controller: widget.addressController,
            hintText: 'Street, Barangay, City',
            // Matches the 300-char cap in firestore.rules.
            inputFormatters: [LengthLimitingTextInputFormatter(300)],
            onChanged: (_) => widget.onChanged(_isResolvingAddress),
            suffixIcon: _isResolvingAddress
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Set location',
          style: AppTextStyles.label(
            context,
          ).copyWith(
            fontSize: 13,
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 164,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _pinnedLocation ??
                      const LatLng(
                        AppOptions.defaultMapLat,
                        AppOptions.defaultMapLng,
                      ),
                  initialZoom: 14,
                  onTap: (_, latLng) => _onMapTapped(latLng),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.rentease.app',
                  ),
                  if (_pinnedLocation != null)
                    MarkerLayer(
                      rotate: true,
                      markers: [
                        Marker(
                          point: _pinnedLocation!,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.location_pin,
                            color: AppColors.accent,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              MapZoomControls(controller: _mapController),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.onInk,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.appColors.fieldBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.scrim.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: _isLocatingCurrent ? null : _locateCurrentPosition,
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: _isLocatingCurrent
                          ? const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                              size: 19,
                              color: AppColors.primary,
                            ),
                    ),
                  ),
                ),
              ),
              if (_pinnedLocation == null)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.onInk.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.appColors.fieldBorder),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.scrim.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          size: 14,
                          color: AppColors.amberBorder,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Tap to pin your property (required)',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11.5,
                            fontWeight: FontWeight.normal,
                            color: AppColors.slate700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_isResolvingAddress) ...[
          const SizedBox(height: 6),
          const Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 6),
              Text(
                'Fetching location...',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ] else if (_pinnedLocation != null) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Pinned: ${widget.addressController.text.isNotEmpty ? widget.addressController.text : '${_pinnedLocation!.latitude.toStringAsFixed(4)}, ${_pinnedLocation!.longitude.toStringAsFixed(4)}'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
