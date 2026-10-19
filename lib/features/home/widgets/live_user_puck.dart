import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Modern Google Maps-style live GPS user puck with directional heading cone.
class LiveUserPuck extends StatelessWidget {
  final double? heading; // 0..360 degrees from North

  const LiveUserPuck({
    this.heading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1A73E8); // Google Maps navigation blue

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Directional Heading Beam/Cone (if heading is available)
          if (heading != null)
            Transform.rotate(
              angle: (heading! * math.pi) / 180,
              child: CustomPaint(
                size: const Size(48, 48),
                painter: _HeadingConePainter(color: brandBlue),
              ),
            ),

          // Outer pulse ring
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brandBlue.withValues(alpha: 0.18),
            ),
          ),

          // Core blue circle with white outline & drop shadow
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: brandBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a soft directional field-of-view cone pointing forward.
class _HeadingConePainter extends CustomPainter {
  final Color color;

  const _HeadingConePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 60-degree cone centered pointing upward (-90 degrees)
    const sweepAngle = math.pi / 3;
    const startAngle = -math.pi / 2 - (sweepAngle / 2);

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
      )
      ..close();

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.45),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeadingConePainter oldDelegate) => color != oldDelegate.color;
}

/// Floating Re-center FAB button (Google Maps style) that snaps the camera back to user location.
class RecenterFloatingButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isTracking;

  const RecenterFloatingButton({
    required this.onTap,
    this.isTracking = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              isTracking ? Icons.navigation_rounded : Icons.my_location_rounded,
              size: 22,
              color: isTracking ? const Color(0xFF1A73E8) : const Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}
