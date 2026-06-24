part of 'onboarding_cubit.dart';

/// State for the onboarding flow: which page is visible and the page content.
class OnboardingState extends Equatable {
  const OnboardingState({required this.currentPage, required this.pages});

  /// Zero-based index of the currently visible page.
  final int currentPage;

  /// The ordered onboarding pages being displayed.
  final List<OnboardingPageData> pages;

  /// Whether the current page is the final page in the flow.
  bool get isLastPage => currentPage >= pages.length - 1;

  /// Total number of pages, exposed for the page indicator.
  int get pageCount => pages.length;

  OnboardingState copyWith({int? currentPage}) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      pages: pages,
    );
  }

  @override
  List<Object?> get props => <Object?>[currentPage, pages];
}
