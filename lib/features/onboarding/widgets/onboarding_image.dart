import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Full-bleed hero image for a single onboarding page.
///
/// Falls back to a brand gradient if the asset fails to load so the layout
/// never collapses.
class OnboardingImage extends StatelessWidget {
  const OnboardingImage({required this.asset, super.key});

  /// Asset path of the image to display.
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (context, error, stackTrace) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, AppColors.ink],
        ),
      ),
    );
  }
}
