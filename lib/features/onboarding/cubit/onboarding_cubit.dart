import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/onboarding_page_data.dart';

part 'onboarding_state.dart';

/// Drives the onboarding flow: tracks the visible page and advances through it.
///
/// Holds no UI concerns (the [PageController] lives in the view); it only owns
/// which page is considered active and whether the flow is complete.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit()
      : super(
          const OnboardingState(
            currentPage: 0,
            pages: OnboardingPageData.pages,
          ),
        );

  /// Called when the user swipes the [PageView] to a new page.
  void pageChanged(int index) {
    if (index == state.currentPage) return;
    emit(state.copyWith(currentPage: index));
  }

  /// Advances to the next page when "Next" is tapped.
  ///
  /// Does nothing on the last page — the view shows "Get Started" there and
  /// handles navigation out of the flow instead.
  void nextPage() {
    if (state.isLastPage) return;
    emit(state.copyWith(currentPage: state.currentPage + 1));
  }

  /// Jumps straight to the final page when "Skip" is tapped.
  void skip() {
    emit(state.copyWith(currentPage: state.pages.length - 1));
  }
}
