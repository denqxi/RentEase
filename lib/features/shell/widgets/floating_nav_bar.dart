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
    this.activeIconSize,
  }) : assert(icon != null || svgString != null, 'Either icon or svgString must be provided');

  final IconData? icon;
  final String? svgString;
  final int badgeCount;
  final String label;
  final double? iconSize;
  final double? activeIconSize;
}

/// Animated floating nav bar shared by tenant and owner shells.
///
/// Active tab floats a teal circle above the bar; inactive tabs show a plain
/// dark icon. Wrap the host Scaffold with [extendBody: true] so page content
/// scrolls under the bar.
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

  static const double _outerD  = 62.0;
  static const double _innerD  = 48.0;
  static const double _barH    = 46.0;
  static const double _totalH  = 70.0;
  static const double _barTopPx = _totalH - _barH; // 24
  static const double _inactiveY = 0.34;

  @override
  Widget build(BuildContext context) {
    final double rawBottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomInset = rawBottomInset > 0 ? rawBottomInset : 4.0;

    return SizedBox(
      height: _totalH + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // Background bar — extends all the way down through the bottom
          // safe-area inset so no page content shows through beneath it.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: _barH + bottomInset,
              decoration: BoxDecoration(
                color: context.appColors.surface,
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: AppColors.scrimFaint,
                    blurRadius: 12,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
            ),
          ),
          // Nav items — responsive width centering for wider displays (tablets/landscape)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: bottomInset,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(
                    items.length,
                    (i) => Expanded(
                      child: _NavItem(
                        data: items[i],
                        selected: i == selectedIndex,
                        onTap: () => onTap(i),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final FloatingNavBarItem data;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: widget.selected ? 1.0 : 0.0,
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      widget.selected ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // Inactive icon — fades out as active animates in
              Align(
                alignment: const Alignment(0, FloatingNavBar._inactiveY),
                child: Opacity(
                  opacity: (1.0 - _fade.value).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.8 + 0.2 * (1.0 - _fade.value),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        _buildIcon(color: const Color(0xFF334155), active: false),
                        if (widget.data.badgeCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.unread,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Active content — scales + fades in
              Opacity(
                opacity: _fade.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _scale.value.clamp(0.0, 1.5),
                  alignment: const Alignment(0, -0.6),
                  child: _buildActiveContent(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveContent() {
    const double barTop  = FloatingNavBar._barTopPx;
    const double tealTop = barTop - FloatingNavBar._innerD / 2;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        // Gray outer ring — bottom half clipped at bar top
        Positioned(
          top: barTop,
          left: 0,
          right: 0,
          child: Center(
            child: ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 0.5,
                child: Container(
                  width: FloatingNavBar._outerD,
                  height: FloatingNavBar._outerD,
                  decoration: BoxDecoration(
                    color: context.appColors.fieldFill,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Teal circle floating above bar
        Positioned(
          top: tealTop,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: FloatingNavBar._innerD,
              height: FloatingNavBar._innerD,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _buildIcon(color: AppColors.onInk, active: true),
                  const SizedBox(height: 1.5),
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.15,
                    child: Text(
                      widget.data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onInk,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon({required Color color, required bool active}) {
    final double defaultSize = active ? 18.0 : 20.0;
    final double size = active
        ? (widget.data.activeIconSize ??
            (widget.data.iconSize != null
                ? widget.data.iconSize!
                : defaultSize))
        : (widget.data.iconSize ?? defaultSize);
    final double strokeWidth = active ? 1.75 : 1.35;

    if (widget.data.svgString != null) {
      return AppSvgIcon(
        svgString: widget.data.svgString!,
        size: size,
        color: color,
        strokeWidth: strokeWidth,
        semanticLabel: widget.data.label,
      );
    }

    return Icon(
      widget.data.icon,
      size: size,
      color: color,
      semanticLabel: widget.data.label,
    );
  }
}