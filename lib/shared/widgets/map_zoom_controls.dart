import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../core/constants/app_colors.dart';

/// Zoom in/out buttons for flutter_map surfaces. Place inside the map's
/// Stack; positions itself bottom-right.
class MapZoomControls extends StatelessWidget {
  const MapZoomControls({required this.controller, super.key});

  final MapController controller;

  void _zoom(double delta) {
    final camera = controller.camera;
    controller.move(camera.center, camera.zoom + delta);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      bottom: 8,
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.appColors.fieldBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ZoomButton(icon: Icons.add_rounded, onTap: () => _zoom(1)),
            Divider(
              height: 1,
              thickness: 1,
              color: context.appColors.fieldBorder,
            ),
            _ZoomButton(icon: Icons.remove_rounded, onTap: () => _zoom(-1)),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 20, color: context.appColors.textPrimary),
      ),
    );
  }
}
