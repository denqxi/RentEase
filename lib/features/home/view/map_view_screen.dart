import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/map_zoom_controls.dart';
import '../../../shared/widgets/match_badge.dart';
import '../../../shared/widgets/verified_badge.dart';
import 'property_detail_screen.dart';

/// Map browsing view — Leaflet-style OpenStreetMap (flutter_map) showing
/// compatible properties as pins around the tenant's POI. Pin color follows
/// the match-tier color psychology (green = strong, amber = moderate,
/// red = weak). Tap a pin to preview, tap the preview for full details.
class MapViewScreen extends StatefulWidget {
  const MapViewScreen({required this.properties, super.key});

  final List<Map<String, dynamic>> properties;

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final _mapController = MapController();
  int? _selectedIndex;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final properties = widget.properties;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        title: Text(
          'Map view',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: context.appColors.fieldBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                    initialCenter: const LatLng(
                      MockData.tenantPoiLat,
                      MockData.tenantPoiLng,
                    ),
                    initialZoom: 13.5,
                    // Tapping empty map space dismisses the callout.
                    onTap: (_, _) => setState(() => _selectedIndex = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.rentease.app',
                    ),
                    MarkerLayer(
                      markers: [
                        // POI marker — tenant's school/work
                        Marker(
                          point: const LatLng(
                            MockData.tenantPoiLat,
                            MockData.tenantPoiLng,
                          ),
                          width: 120,
                          height: 54,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school_rounded,
                                  color: AppColors.accent, size: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.appColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: context.appColors.fieldBorder),
                                ),
                                child: Text(
                                  'Your POI',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: context.appColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Property pins — color = match strength
                        for (int i = 0; i < properties.length; i++)
                          Marker(
                            point: LatLng(
                              (properties[i]['latitude'] as num).toDouble(),
                              (properties[i]['longitude'] as num).toDouble(),
                            ),
                            width: 60,
                            height: 56,
                            child: _PropertyPin(
                              property: properties[i],
                              isSelected: _selectedIndex == i,
                              onTap: () =>
                                  setState(() => _selectedIndex = i),
                            ),
                          ),
                        // Floating callout above the selected pin —
                        // drawn last so it sits on top of everything.
                        if (_selectedIndex != null)
                          Marker(
                            point: LatLng(
                              (properties[_selectedIndex!]['latitude'] as num)
                                  .toDouble(),
                              (properties[_selectedIndex!]['longitude'] as num)
                                  .toDouble(),
                            ),
                            width: 240,
                            height: 150,
                            // Anchor the widget's bottom to the pin point so
                            // the callout floats above it.
                            alignment: Alignment.topCenter,
                            child: _PinCallout(
                              property: properties[_selectedIndex!],
                              rank: _selectedIndex! + 1,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PropertyDetailScreen(
                                    property: properties[_selectedIndex!],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                    MapZoomControls(controller: _mapController),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Tap a pin to preview a property. Pin color shows match strength.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                color: context.appColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyPin extends StatelessWidget {
  const _PropertyPin({
    required this.property,
    required this.isSelected,
    required this.onTap,
  });

  final Map<String, dynamic> property;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int percent =
        ((property['ciScore'] as num).toDouble() * 100).round();
    final Color color = MatchBadge.colorFor(percent);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? context.appColors.ink
                    : AppColors.onInk,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              '$percent%',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.onInk,
              ),
            ),
          ),
          Icon(Icons.location_pin, color: color, size: 26),
        ],
      ),
    );
  }
}

/// Compact callout card floating above the selected pin, with a pointer
/// triangle. Tapping it opens the full property detail.
class _PinCallout extends StatelessWidget {
  const _PinCallout({
    required this.property,
    required this.rank,
    required this.onTap,
  });

  final Map<String, dynamic> property;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int percent =
        ((property['ciScore'] as num).toDouble() * 100).round();
    final Color tierColor = MatchBadge.colorFor(percent);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 230,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: context.appColors.fieldBorder, width: 0.5),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        property['name'] as String,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (property['isVerified'] as bool? ?? false)
                      const VerifiedBadge(isVerified: true, isSmall: true),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '₱${property['rent']}/mo · ${property['distance']} km',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          color: context.appColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$percent% match',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tierColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Pointer triangle linking the card to its pin.
          CustomPaint(
            size: const Size(14, 7),
            painter: _CalloutArrowPainter(
              color: context.appColors.surface,
              borderColor: context.appColors.fieldBorder,
            ),
          ),
          // Clearance so the card floats above the 56px-tall pin marker.
          const SizedBox(height: 56),
        ],
      ),
    );
  }
}

class _CalloutArrowPainter extends CustomPainter {
  const _CalloutArrowPainter({required this.color, required this.borderColor});

  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(covariant _CalloutArrowPainter oldDelegate) =>
      color != oldDelegate.color || borderColor != oldDelegate.borderColor;
}
