import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'listing_image_placeholder.dart';

/// Swipeable photos of one property with page dots. Falls back to the
/// placeholder image when the listing has no uploaded photos.
class PropertyPhotoCarousel extends StatefulWidget {
  const PropertyPhotoCarousel({
    required this.photos,
    required this.seed,
    this.fullSize = true,
    super.key,
  });

  final List<String> photos;

  /// Placeholder selector, used when [photos] is empty.
  final int seed;
  final bool fullSize;

  @override
  State<PropertyPhotoCarousel> createState() => _PropertyPhotoCarouselState();
}

class _PropertyPhotoCarouselState extends State<PropertyPhotoCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    if (photos.length < 2) {
      return ListingImagePlaceholder(
        seed: widget.seed,
        photoUrl: photos.isEmpty ? null : photos.first,
        fullSize: widget.fullSize,
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: photos.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => ListingImagePlaceholder(
            seed: widget.seed,
            photoUrl: photos[i],
            fullSize: widget.fullSize,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < photos.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AppColors.onInk
                        : AppColors.onInk.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
