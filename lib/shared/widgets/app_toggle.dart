import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Custom toggle switch. Does not use Flutter's built-in Switch widget.
///
/// Width 44 px, height 24 px. White thumb, configurable active track color.
class AppToggle extends StatelessWidget {
  const AppToggle({
    required this.value,
    required this.onChanged,
    this.activeColor,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  /// Defaults to [AppColors.primaryMid] when null.
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: CustomPaint(
        size: const Size(44, 24),
        painter: _TogglePainter(
          value: value,
          activeColor: activeColor ?? AppColors.primaryMid,
        ),
      ),
    );
  }
}

class _TogglePainter extends CustomPainter {
  const _TogglePainter({required this.value, required this.activeColor});

  final bool value;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = value ? activeColor : AppColors.border
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(size.height / 2),
      ),
      trackPaint,
    );

    final thumbRadius = size.height / 2 - 2;
    final thumbCenterX =
        value ? size.width - thumbRadius - 2 : thumbRadius + 2;

    canvas.drawCircle(
      Offset(thumbCenterX, size.height / 2),
      thumbRadius,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_TogglePainter old) =>
      old.value != value || old.activeColor != activeColor;
}
