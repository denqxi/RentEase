import 'package:flutter/material.dart';

/// Renders a property photo, picked by [seed] so each listing looks distinct.
///
/// Falls back to a colour-gradient placeholder if the asset is missing.
class ListingImagePlaceholder extends StatelessWidget {
  const ListingImagePlaceholder({required this.seed, super.key});

  final int seed;

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
            colors: <Color>[Color(0xFFDBC59C), Color(0xFF8B6914)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        2 => const LinearGradient(
            colors: <Color>[Color(0xFF2C3E6B), Color(0xFF0D1B3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        3 => const LinearGradient(
            colors: <Color>[Color(0xFFB0D4E0), Color(0xFF5A9AB0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        4 => const LinearGradient(
            colors: <Color>[Color(0xFFCDAA8C), Color(0xFF8B6250)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        _ => const LinearGradient(
            colors: <Color>[Color(0xFF4AA8D8), Color(0xFF1E5C8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
      };
}
