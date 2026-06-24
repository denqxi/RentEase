import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/onboarding_card.dart';
import '../widgets/onboarding_image.dart';

/// Entry point for the onboarding flow.
///
/// Provides the [OnboardingCubit] and renders the swipeable page experience.
/// [onComplete] is invoked when the user finishes or skips onboarding.
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

/// Owns the [PageController] — the one piece of local UI state the flow needs —
/// and keeps it in sync with the [OnboardingCubit].
class _OnboardingView extends StatefulWidget {
  const _OnboardingView({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateTo(int page) {
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
      backgroundColor: AppColors.ink,
      body: BlocListener<OnboardingCubit, OnboardingState>(
        // When the cubit advances the page (e.g. via "Next" or "Skip"),
        // drive the PageController so the swipe and the buttons stay in sync.
        listenWhen: (previous, current) =>
            previous.currentPage != current.currentPage,
        listener: (context, state) {
          if (_pageController.page?.round() != state.currentPage) {
            _animateTo(state.currentPage);
          }
        },
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: cubit.pageChanged,
                itemCount: cubit.state.pageCount,
                itemBuilder: (context, index) =>
                    OnboardingImage(asset: cubit.state.pages[index].imageAsset),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: BlocBuilder<OnboardingCubit, OnboardingState>(
                builder: (context, state) {
                  return OnboardingCard(
                    state: state,
                    onPrimary: () {
                      if (state.isLastPage) {
                        widget.onComplete();
                      } else {
                        cubit.nextPage();
                      }
                    },
                    onSecondary: () {
                      if (state.isLastPage) {
                        // "I already have an account".
                        widget.onComplete();
                      } else {
                        // "Skip" — leave onboarding entirely.
                        widget.onComplete();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
