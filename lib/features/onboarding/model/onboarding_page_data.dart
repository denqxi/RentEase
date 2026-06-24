import 'package:equatable/equatable.dart';

/// Immutable content for a single onboarding page.
class OnboardingPageData extends Equatable {
  const OnboardingPageData({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
  });

  /// Path to the full-bleed hero image shown at the top of the page.
  final String imageAsset;

  /// Short, bold headline.
  final String title;

  /// Supporting description shown beneath the title.
  final String subtitle;

  /// The ordered set of pages presented in the onboarding flow.
  static const List<OnboardingPageData> pages = <OnboardingPageData>[
    OnboardingPageData(
      imageAsset: 'assets/images/hero-pool.png',
      title: 'Find the right home',
      subtitle:
          'Explore rooms, houses, and apartments near you — all in one calm, '
          'beautiful place.',
    ),
    OnboardingPageData(
      imageAsset: 'assets/images/hero-interior.png',
      title: 'Matched to your lifestyle',
      subtitle:
          'RentEase scores every listing on how well it fits your budget, '
          'location, and preferences.',
    ),
    OnboardingPageData(
      imageAsset: 'assets/images/hero-modern.png',
      title: 'Connect with the right people',
      subtitle:
          'Tenants and landlords matched on real compatibility — not just '
          'price.',
    ),
  ];

  @override
  List<Object?> get props => <Object?>[imageAsset, title, subtitle];
}
