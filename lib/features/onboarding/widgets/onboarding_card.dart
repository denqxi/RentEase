import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../cubit/onboarding_cubit.dart';
import 'onboarding_page_indicator.dart';

/// Text + capsule indicator overlay rendered directly on top of the hero image.
///
/// Fully performance-optimized with [RepaintBoundary] to ensure 60/120fps
/// rasterization on production mobile devices.
class OnboardingCard extends StatefulWidget {
  const OnboardingCard({
    required this.state,
    super.key,
  });

  final OnboardingState state;

  @override
  State<OnboardingCard> createState() => _OnboardingCardState();
}

class _OnboardingCardState extends State<OnboardingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Title: slide-up + fade
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;

  // Subtitle: slide-up + fade
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;

  // Indicator: slide-up + fade
  late final Animation<double> _indicatorOpacity;
  late final Animation<Offset> _indicatorSlide;

  @override
  void initState() {
    super.initState();
    // 8.0s on the first screen and last page, 350ms on intermediate pages
    final duration = (widget.state.currentPage == 0 || widget.state.isLastPage)
        ? const Duration(milliseconds: 8000)
        : const Duration(milliseconds: 350);

    _controller = AnimationController(vsync: this, duration: duration);

    // Title animation (smooth slide up)
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.70, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.45),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
    ));

    // Subtitle animation (smooth slide up)
    _subtitleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.80, curve: Curves.easeOut),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.40),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.95, curve: Curves.easeOutCubic),
    ));

    // Indicator animation (smooth slide up)
    _indicatorOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.90, curve: Curves.easeOut),
    );
    _indicatorSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.state.pages[widget.state.currentPage];

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Title: smooth slide-up
            SlideTransition(
              position: _titleSlide,
              child: FadeTransition(
                opacity: _titleOpacity,
                child: Text(
                  page.title,
                  style: AppTextStyles.heading(context).copyWith(
                    color: const Color(0xFFFFFFFF),
                    fontSize: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle: smooth slide-up
            SlideTransition(
              position: _subtitleSlide,
              child: FadeTransition(
                opacity: _subtitleOpacity,
                child: Text(
                  page.subtitle,
                  style: AppTextStyles.body(context).copyWith(
                    color: const Color(0xCCFFFFFF),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3-bar capsule indicator: smooth slide-up
            SlideTransition(
              position: _indicatorSlide,
              child: FadeTransition(
                opacity: _indicatorOpacity,
                child: OnboardingPageIndicator(
                  count: widget.state.pageCount,
                  currentIndex: widget.state.currentPage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
