import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Lightweight skeleton loading state for the tenant home feed.
///
/// Faithfully reproduces the skeleton layout from design:
/// 1. "Recommended for you" / "Your top 3 property matches" header with 3 dot indicators
/// 2. Horizontal carousel with the first card and second card peeking in on the right
/// 3. "Other listings" / "Properties that may not meet all your preferences." section
/// 4. Full-width skeleton card in the other listings section
///
/// Each card features a soft photo container with mountain placeholder icon,
/// top-right circular heart placeholder, title bar, location pin + address bar,
/// subtle divider, and bottom badge square + price pill bars.
class HomeContentSkeleton extends StatefulWidget {
  const HomeContentSkeleton({super.key});

  @override
  State<HomeContentSkeleton> createState() => _HomeContentSkeletonState();
}

class _HomeContentSkeletonState extends State<HomeContentSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _opacityAnim = Tween<double>(begin: 0.55, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.84).clamp(280.0, 360.0);

    return AnimatedBuilder(
      animation: _opacityAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Section 1 Header: Recommended for you ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Recommended for you',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate500,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Your top 3 property matches',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 17.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  // 3 circular dot indicators
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.slate300,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.slate300,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.slate300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Section 1 Horizontal Cards (First card + peeking card) ─
            SizedBox(
              height: 295,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: const _SkeletonCard(),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: cardWidth,
                    child: const _SkeletonCard(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Section 2 Header: Other listings ─────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Other listings',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Properties that may not meet all your preferences.',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Section 2 Vertical Card (Full width) ─────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _SkeletonCard(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable skeleton card faithfully matching the card in the design.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  static const Color _placeholderColor = AppColors.slate200;
  static const Color _iconPlaceholderColor = AppColors.slate400;
  static const Color _borderColor = AppColors.slate200;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Image Placeholder with Mountain Icon & Heart Circle
          Container(
            height: 152,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _placeholderColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Mountain / landscape image silhouette icon
                const Center(
                  child: Icon(
                    Icons.image_rounded,
                    size: 46,
                    color: _iconPlaceholderColor,
                  ),
                ),
                // Top-right circular heart button placeholder
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _iconPlaceholderColor.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Title bar placeholder
          Container(
            width: 175,
            height: 16,
            decoration: BoxDecoration(
              color: _placeholderColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 9),

          // Location pin + address placeholder
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 15,
                color: AppColors.slate300,
              ),
              const SizedBox(width: 5),
              Container(
                width: 110,
                height: 13,
                decoration: BoxDecoration(
                  color: _placeholderColor,
                  borderRadius: BorderRadius.circular(6.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Divider line
          const Divider(
            height: 1,
            thickness: 0.8,
            color: _borderColor,
          ),
          const SizedBox(height: 12),

          // Bottom row: Square badge + text bar on left, price bar on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _placeholderColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 82,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _placeholderColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              ),
              Container(
                width: 82,
                height: 18,
                decoration: BoxDecoration(
                  color: _placeholderColor,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
