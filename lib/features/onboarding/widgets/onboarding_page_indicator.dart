import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';

/// Animated row of capsule bars showing progress through the onboarding pages.
///
/// The active page is a wider, sky-blue pill; inactive pages are short grey
/// capsules. All transitions animate with a spring-like easing curve.
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
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          _CapsuleBar(active: i == currentIndex, key: ValueKey<int>(i)),
      ],
    );
  }
}

class _CapsuleBar extends StatelessWidget {
  const _CapsuleBar({required this.active, super.key});

  final bool active;

  // Active bar is significantly wider and more prominent.
  static const double _activeWidth = 36;
  static const double _inactiveWidth = 16;
  static const double _height = 6;

  // Sky-blue for active, light grey for inactive.
  static const Color _activeColor = Color(0xFF1A7BBF);
  static const Color _inactiveColor = Color(0xFFCBDFED);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      height: _height,
      width: active ? _activeWidth : _inactiveWidth,
      decoration: BoxDecoration(
        color: active ? _activeColor : _inactiveColor,
        borderRadius: BorderRadius.circular(_height / 2),
      ),
    );
  }
}
