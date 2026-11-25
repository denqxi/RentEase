import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

import '../../../shared/widgets/app_svg_icon.dart';

class FloatingNavBarItem {
  const FloatingNavBarItem({
    this.icon,
    this.svgString,
    required this.label,
    this.badgeCount = 0,
    this.iconSize,
  }) : assert(icon != null || svgString != null, 'Either icon or svgString must be provided');

  final IconData? icon;
  final String? svgString;
  final int badgeCount;
  final String label;
  final double? iconSize;
}

/// Bottom navigation shared by the tenant, owner and admin shells.
///
/// The top edge bulges under the selected tab, and the bulge glides across
/// when the tab changes. Every tab shows its label. The flat edge is the top of
/// the bar, so there is no empty strip above it (leave `extendBody` off); only
/// the bulge itself reaches over the page.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    super.key,
  });

  final List<FloatingNavBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  /// How far the bulge rises above the flat part of the top edge.
  static const double bulgeRise = 14;

  /// Keeps the tabs together on tablets and in landscape.
  static const double _maxRowWidth = 520;

  static const Duration _glide = Duration(milliseconds: 320);

  /// The teal dot that rides in the bulge, and the icon centre inside it,
  /// measured from the flat edge.
  static const double _dotRadius = 18;
  static const double _raisedY = 9;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final still = MediaQuery.disableAnimationsOf(context);

    // [position] is the bulge's place in tab units, e.g. 1.5 is halfway
    // between the second and third tabs.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: selectedIndex.toDouble()),
      duration: still ? Duration.zero : _glide,
      curve: Curves.easeOutCubic,
      builder: (context, position, _) => CustomPaint(
        painter: _BulgePainter(
          position: position,
          count: items.length,
          fill: colors.surface,
          edge: colors.fieldBorder,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            top: false,
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxRowWidth),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavItem(
                          data: items[i],
                          selected: i == selectedIndex,
                          // 1 under the bulge, falling to 0 one tab away.
                          lift: (1 - (position - i).abs()).clamp(0.0, 1.0),
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BulgePainter extends CustomPainter {
  const _BulgePainter({
    required this.position,
    required this.count,
    required this.fill,
    required this.edge,
  });

  final double position;
  final int count;
  final Color fill;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    const rise = FloatingNavBar.bulgeRise;
    final rowWidth = math.min(size.width, FloatingNavBar._maxRowWidth);
    final tabWidth = rowWidth / count;
    final center = (size.width - rowWidth) / 2 + (position + 0.5) * tabWidth;
    final half = math.min(tabWidth * 0.82, 52.0);

    // The flat edge runs past both sides so an end tab's bulge stays smooth.
    final left = math.min(0.0, center - half) - 1;
    final right = math.max(size.width, center + half) + 1;
    final top = Path()
      ..moveTo(left, 0)
      ..lineTo(center - half, 0)
      ..cubicTo(
        center - half * 0.52,
        0,
        center - half * 0.46,
        -rise,
        center,
        -rise,
      )
      ..cubicTo(
        center + half * 0.46,
        -rise,
        center + half * 0.52,
        0,
        center + half,
        0,
      )
      ..lineTo(right, 0);
    final body = Path.from(top)
      ..lineTo(right, size.height)
      ..lineTo(left, size.height)
      ..close();

    canvas.drawPath(
      body.shift(const Offset(0, -2)),
      Paint()
        ..color = AppColors.scrimFaint
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(body, Paint()..color = fill);
    // One dot travels with the bulge; the icons rise into it.
    canvas.drawCircle(
      Offset(center, FloatingNavBar._raisedY),
      FloatingNavBar._dotRadius,
      Paint()..color = AppColors.primary,
    );
    canvas.drawPath(
      top,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BulgePainter old) =>
      old.position != position ||
      old.count != count ||
      old.fill != fill ||
      old.edge != edge;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.lift,
    required this.onTap,
  });

  final FloatingNavBarItem data;
  final bool selected;
  final double lift;
  final VoidCallback onTap;

  static const double _slotHeight = 32;
  static const double _iconBox = 36;

  /// Icon centre when resting in the bar.
  static const double _restY = 19;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final iconColor = Color.lerp(
      colors.textSecondary,
      AppColors.onInk,
      lift,
    )!;
    final size = data.iconSize ?? 22;
    final icon = data.svgString != null
        ? AppSvgIcon(
            svgString: data.svgString!,
            size: size,
            color: iconColor,
            strokeWidth: 1.4 + 0.4 * lift,
          )
        : Icon(data.icon, size: size, color: iconColor);
    final centerY = _restY + (FloatingNavBar._raisedY - _restY) * lift;

    return Semantics(
      button: true,
      selected: selected,
      label: data.badgeCount > 0
          ? '${data.label}, ${data.badgeCount} unread'
          : data.label,
      onTap: onTap,
      excludeSemantics: true,
      // The gliding bulge is the tap feedback; no ripple or grey box.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _slotHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      top: centerY - _iconBox / 2,
                      child: SizedBox.square(
                        dimension: _iconBox,
                        child: Center(
                          child: Badge(
                            isLabelVisible: data.badgeCount > 0,
                            smallSize: 9,
                            backgroundColor: AppColors.unread,
                            child: icon,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Long labels shrink to their tab rather than being cut off.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    data.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected
                          ? colors.textPrimary
                          : colors.textSecondary,
                      height: 1.2,
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
