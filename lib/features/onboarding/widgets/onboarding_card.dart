import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/onboarding_cubit.dart';
import 'onboarding_footer.dart';
import 'onboarding_page_indicator.dart';

/// The white, rounded card pinned to the bottom of the onboarding screen.
class OnboardingCard extends StatelessWidget {
  const OnboardingCard({
    required this.state,
    required this.onPrimary,
    required this.onSecondary,
    super.key,
  });

  final OnboardingState state;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final page = state.pages[state.currentPage];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              OnboardingPageIndicator(
                count: state.pageCount,
                currentIndex: state.currentPage,
              ),
              SizedBox(height: AppSpacing.xl),
              // ValueKey forces Flutter to unmount the old widget and mount a
              // fresh one on every page change, which restarts the entrance
              // animation from the beginning.
              _OnboardingText(
                key: ValueKey<int>(state.currentPage),
                title: page.title,
                subtitle: page.subtitle,
              ),
              SizedBox(height: AppSpacing.xl),
              OnboardingFooter(
                isLastPage: state.isLastPage,
                onPrimary: onPrimary,
                onSecondary: onSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Staggered slide-up + fade entrance for a single page's title and subtitle.
///
/// Uses an absolute 40 px Y-offset so the motion is clearly visible regardless
/// of text height. Title leads; subtitle starts 120 ms later.
class _OnboardingText extends StatefulWidget {
  const _OnboardingText({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  State<_OnboardingText> createState() => _OnboardingTextState();
}

class _OnboardingTextState extends State<_OnboardingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Title — occupies the first 80 % of the timeline.
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleY;

  // Subtitle — starts 120 ms in (interval ≈ 0.22 of 550 ms).
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _subtitleY;

  static const Duration _duration = Duration(milliseconds: 550);

  /// Distance each text line travels upward, in logical pixels.
  static const double _slidePixels = 40.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);

    // Title
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _titleY = Tween<double>(begin: _slidePixels, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // Subtitle
    _subtitleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.22, 0.88, curve: Curves.easeOut),
    );
    _subtitleY = Tween<double>(begin: _slidePixels, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FadeTransition(
          opacity: _titleOpacity,
          child: AnimatedBuilder(
            animation: _titleY,
            child: Text(widget.title, style: AppTextStyles.heading(context)),
            builder: (_, Widget? child) => Transform.translate(
              offset: Offset(0, _titleY.value),
              child: child,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        FadeTransition(
          opacity: _subtitleOpacity,
          child: AnimatedBuilder(
            animation: _subtitleY,
            child: Text(widget.subtitle, style: AppTextStyles.body(context)),
            builder: (_, Widget? child) => Transform.translate(
              offset: Offset(0, _subtitleY.value),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
