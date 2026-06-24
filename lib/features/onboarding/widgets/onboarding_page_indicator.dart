import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Animated row of dots showing progress through the onboarding pages.
///
/// The active page is rendered as a wider pill; inactive pages are small dots.
/// All size, width, and colour changes animate with a slight spring curve so
/// the indicator feels alive rather than instant.
class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    required this.count,
    required this.currentIndex,
    super.key,
  });

  /// Total number of pages.
  final int count;

  /// Index of the currently active page.
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          _Dot(active: i == currentIndex, key: ValueKey<int>(i)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active, super.key});

  final bool active;

  // Active pill is wider and taller than inactive dots.
  static const double _activeWidth = 28;
  static const double _inactiveWidth = 8;
  static const double _height = 8;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      height: _height,
      width: active ? _activeWidth : _inactiveWidth,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.indicatorInactive,
        borderRadius: BorderRadius.circular(_height / 2),
      ),
    );
  }
}
