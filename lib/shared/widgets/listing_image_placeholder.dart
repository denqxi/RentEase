import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

import '../../core/utils/cloudinary_url.dart';

/// Renders a property photo, picked by [seed] so each listing looks distinct.
///
/// If [photoUrl] is set (first uploaded listing photo) it is shown, sized via
/// [CloudinaryUrl]; otherwise, or if it fails to load, the seeded asset is used.
/// Falls back to a colour-gradient placeholder if the asset is missing.
class ListingImagePlaceholder extends StatelessWidget {
  const ListingImagePlaceholder({
    required this.seed,
    this.photoUrl,
    this.fullSize = false,
    super.key,
  });

  final int seed;
  final String? photoUrl;

  /// Use the larger rendition (detail screens) instead of the thumbnail.
  final bool fullSize;

  static const List<String> _assets = <String>[
    'assets/images/hero-room.png',
    'assets/images/hero-modern.png',
    'assets/images/hero-pool.png',
    'assets/images/hero-interior.png',
    'assets/images/hero-building.png',
  ];

  @override
  Widget build(BuildContext context) {
    final String asset = _assets[(seed - 1) % _assets.length];
    final url = photoUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        fullSize ? CloudinaryUrl.full(url) : CloudinaryUrl.thumbnail(url),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(asset),
      );
    }
    return _fallback(asset);
  }

  Widget _fallback(String asset) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => DecoratedBox(
        decoration: BoxDecoration(gradient: _gradient),
        child: const SizedBox.expand(),
      ),
    );
  }

  LinearGradient get _gradient => switch (seed) {
    1 => const LinearGradient(
      colors: <Color>[AppColors.placeholderSandA, AppColors.placeholderSandB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    2 => const LinearGradient(
      colors: <Color>[AppColors.placeholderNavyA, AppColors.placeholderNavyB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    3 => const LinearGradient(
      colors: <Color>[AppColors.placeholderSkyA, AppColors.placeholderSkyB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    4 => const LinearGradient(
      colors: <Color>[AppColors.placeholderClayA, AppColors.placeholderClayB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    _ => const LinearGradient(
      colors: <Color>[AppColors.placeholderBlueA, AppColors.placeholderBlueB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  };
}
