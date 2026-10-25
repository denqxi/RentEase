import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Universal widget for rendering SVG icon strings with consistent sizing,
/// theme-aware coloring, and optimal performance.
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon({
    required this.svgString,
    this.size = 24.0,
    this.color,
    this.semanticLabel,
    this.strokeWidth,
    super.key,
  });

  /// The raw SVG XML string to render.
  final String svgString;

  /// Width and height of the icon (square bounding box).
  final double size;

  /// Optional color to tint the SVG icon. If null, the SVG's internal colors/gradients are preserved.
  final Color? color;

  /// Optional semantic label for screen readers.
  final String? semanticLabel;

  /// Optional stroke width override to dynamically customize outline thickness.
  final double? strokeWidth;

  static final RegExp _strokeWidthRe = RegExp(r'stroke-width="[^"]*"');

  @override
  Widget build(BuildContext context) {
    final String effectiveSvg = strokeWidth != null
        ? svgString.replaceAll(
            _strokeWidthRe,
            'stroke-width="$strokeWidth"',
          )
        : svgString;

    if (color == null) {
      return SvgPicture.string(
        effectiveSvg,
        width: size,
        height: size,
        semanticsLabel: semanticLabel,
      );
    }

    return SvgPicture.string(
      effectiveSvg,
      width: size,
      height: size,
      semanticsLabel: semanticLabel,
      theme: SvgTheme(currentColor: color!),
      colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
