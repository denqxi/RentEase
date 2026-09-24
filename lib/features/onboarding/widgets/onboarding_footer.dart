import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

/// Primary action button + "Skip" text link at the bottom of the onboarding
/// screen, with smooth entrance and last-page transitions.
///
/// Performance optimized with [RepaintBoundary] and cached layout definitions.
class OnboardingFooter extends StatefulWidget {
  const OnboardingFooter({
    required this.isLastPage,
    required this.onPrimary,
    required this.onSecondary,
    super.key,
  });

  final bool isLastPage;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  State<OnboardingFooter> createState() => _OnboardingFooterState();
}

class _OnboardingFooterState extends State<OnboardingFooter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // 8.0s smooth, visible slide-up entrance animation on first screen
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.75),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.10, 1.0, curve: Curves.easeOutCubic),
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _entranceCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 8.0 seconds (8000ms) animation specifically for the last page transition
    const lastPageDuration = Duration(milliseconds: 8000);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 160;
        final verticalPadding = isCompact ? AppSpacing.sm : AppSpacing.lg;
        final bottomPadding = isCompact ? AppSpacing.xs : AppSpacing.md;
        final gap = isCompact ? AppSpacing.xs : AppSpacing.md;

        return RepaintBoundary(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  verticalPadding,
                  AppSpacing.lg,
                  bottomPadding,
                ),
                child: AnimatedSize(
                  duration: lastPageDuration,
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Primary CTA button
                      AnimatedContainer(
                        duration: lastPageDuration,
                        curve: Curves.easeInOutCubic,
                        child: AppPrimaryButton(
                          label: widget.isLastPage ? 'Get Started' : 'Next',
                          onPressed: widget.onPrimary,
                        ),
                      ),

                      // Skip button with smooth 8.0s fade and size transition on last page
                      AnimatedCrossFade(
                        duration: lastPageDuration,
                        firstCurve: Curves.easeInOutCubic,
                        secondCurve: Curves.easeInOutCubic,
                        sizeCurve: Curves.easeInOutCubic,
                        crossFadeState: widget.isLastPage
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(height: gap),
                            TextButton(
                              onPressed: widget.onSecondary,
                              child: Text(
                                'Skip',
                                style: AppTextStyles.link(context),
                              ),
                            ),
                          ],
                        ),
                        secondChild: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
