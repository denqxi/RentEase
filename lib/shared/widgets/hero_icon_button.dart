import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// A round icon button with its own background, for controls (back, favorite)
/// that sit on top of a photo and must stay legible on any image.
class HeroIconButton extends StatelessWidget {
  const HeroIconButton({
    required this.icon,
    required this.onPressed,
    this.iconColor,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;

  /// Defaults to [AppColors.ink].
  final Color? iconColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 0,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: iconColor ?? AppColors.ink, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
