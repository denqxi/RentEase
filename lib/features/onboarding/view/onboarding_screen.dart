import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/onboarding_card.dart';
import '../widgets/onboarding_footer.dart';

/// Entry point for the onboarding flow.
///
/// Fully optimized for production performance:
/// - Pre-cached assets & isolated [RepaintBoundary] layers for 60/120fps animations.
/// - Clamped [PageView] prevents bounds recalculation jank.
/// - Uninterrupted gesture pipeline.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({required this.onComplete, super.key});

  /// Called when onboarding should hand off to the next screen (e.g. sign in).
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OnboardingCubit>(
      create: (_) => OnboardingCubit(),
      child: _OnboardingView(onComplete: onComplete),
    );
  }
}

/// Owns the [PageController] and entrance animation for the screen.
class _OnboardingView extends StatefulWidget {
  const _OnboardingView({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  // Cached background gradient decoration to avoid runtime allocations
  static const BoxDecoration _bgDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color(0xFFBDE8F5), // soft sky-blue
        Color(0xFFFFFFFF), // white
      ],
      stops: <double>[0.0, 0.72],
    ),
  );

  @override
  void initState() {
    super.initState();
    // 8.0s smooth, visible slide-up entrance animation after splash screen
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutCubic,
    ));

    // Wait until the route transition finishes to start the animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _entranceCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _animateTo(int page) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();

    return Scaffold(
      body: Container(
        decoration: _bgDecoration,
        child: BlocListener<OnboardingCubit, OnboardingState>(
          listenWhen: (previous, current) =>
              previous.currentPage != current.currentPage,
          listener: (context, state) {
            if (_pageController.hasClients &&
                _pageController.page?.round() != state.currentPage) {
              _animateTo(state.currentPage);
            }
          },
          child: BlocBuilder<OnboardingCubit, OnboardingState>(
            builder: (context, state) {
              return Column(
                children: <Widget>[
                  // ── Hero: isolated in RepaintBoundary for GPU efficiency ──
                  Expanded(
                    child: RepaintBoundary(
                      child: SlideTransition(
                        position: _entranceSlide,
                        child: FadeTransition(
                          opacity: _entranceFade,
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                              child: _HeroFrame(
                                pageController: _pageController,
                                onPageChanged: cubit.pageChanged,
                                state: state,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Footer: sized to content, isolated in RepaintBoundary ─
                  SafeArea(
                    top: false,
                    child: RepaintBoundary(
                      child: OnboardingFooter(
                        isLastPage: state.isLastPage,
                        onPrimary: () {
                          if (state.isLastPage) {
                            widget.onComplete();
                          } else {
                            cubit.nextPage();
                          }
                        },
                        onSecondary: () => widget.onComplete(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero frame with performance optimizations
// ─────────────────────────────────────────────────────────────────────────────

/// Rounded container wrapping the swipeable [PageView] images with smooth
/// container transform animation between pages.
class _HeroFrame extends StatelessWidget {
  const _HeroFrame({
    required this.pageController,
    required this.onPageChanged,
    required this.state,
  });

  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final OnboardingState state;

  // Cached gradient decoration for the dark bottom scrim
  static const BoxDecoration _scrimDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Colors.transparent,
        Color(0xCC000000),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: state.isLastPage
          ? const Duration(milliseconds: 8000)
          : const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: state.isLastPage ? 0.12 : 0.08,
            ),
            blurRadius: state.isLastPage ? 18 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Swipeable images — bound strictly to pageCount with clamping physics
            PageView.builder(
              controller: pageController,
              onPageChanged: onPageChanged,
              itemCount: state.pageCount,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) => Image.asset(
                state.pages[index].imageAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => const _HeroFallback(),
              ),
            ),

            // Dark gradient scrim at the bottom for text legibility
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 240,
              child: DecoratedBox(
                decoration: _scrimDecoration,
              ),
            ),

            // Text + indicator overlay — smooth slide up
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: OnboardingCard(
                  key: ValueKey<int>(state.currentPage),
                  state: state,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFBDE8F5), AppColors.primary],
        ),
      ),
    );
  }
}
