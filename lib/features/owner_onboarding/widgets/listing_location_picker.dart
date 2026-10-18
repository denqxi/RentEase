import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_options.dart';
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
            border: Border.all(
              color: _pinnedLocation != null
                  ? AppColors.accent
                  : context.appColors.fieldBorder,
              width: _pinnedLocation != null ? 1.5 : 1,
            ),
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
                      markers: [
                        Marker(
                          point: _pinnedLocation!,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: Icon(
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
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppRadii.field),
                    border: Border.all(color: context.appColors.fieldBorder),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isResolvingAddress) ...[
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          _pinnedLocation == null
                              ? 'Tap to pin your property (required)'
                              : _isResolvingAddress
                              ? 'Fetching address for pin...'
                              : 'Pinned: ${widget.addressController.text.isNotEmpty ? widget.addressController.text : '${_pinnedLocation!.latitude.toStringAsFixed(4)}, ${_pinnedLocation!.longitude.toStringAsFixed(4)}'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context).copyWith(
                            color: _pinnedLocation != null
                                ? AppColors.accent
                                : context.appColors.textSecondary,
                            fontWeight: _pinnedLocation != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
