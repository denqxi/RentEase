import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Reusable card-over-hero scaffold used for all auth and onboarding screens.
///
/// Renders a full-bleed [hero] behind a white bottom sheet card that covers
/// roughly 70 % of the screen height.
class CardOverHeroLayout extends StatelessWidget {
  const CardOverHeroLayout({
    required this.hero,
    required this.cardContent,
    this.cardHeightFraction = 0.72,
    super.key,
  });

  /// Full-bleed background widget (image or colored container).
  final Widget hero;

  /// Content placed inside the white card.
  final Widget cardContent;

  /// Fraction of screen height the card occupies (default 0.72).
  final double cardHeightFraction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          hero,
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * cardHeightFraction,
              ),
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadii.card),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                child: SafeArea(
                  top: false,
                  child: cardContent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard hero placeholder used when no real photo asset is available.
class HeroPlaceholder extends StatelessWidget {
  const HeroPlaceholder({this.imageAsset, super.key});

  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    if (imageAsset != null) {
      return Image.asset(
        imageAsset!,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, _, _) => const _FallbackHero(),
      );
    }
    return const _FallbackHero();
  }
}

class _FallbackHero extends StatelessWidget {
  const _FallbackHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accentSoft,
      child: Center(
        child: Icon(Icons.home_work_rounded, color: AppColors.accent, size: 64),
      ),
    );
  }
}

/// Step progress dots row shown on onboarding screens.
class StepProgressDots extends StatelessWidget {
  const StepProgressDots({
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (i) {
        final active = i <= currentStep;
        return Padding(
          padding: EdgeInsets.only(right: i < totalSteps - 1 ? AppSpacing.xs : 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? AppColors.accent : context.appColors.indicatorInactive,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

/// Step header row: dots + label.
class OnboardingStepHeader extends StatelessWidget {
  const OnboardingStepHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.label,
    super.key,
  });

  final int currentStep;
  final int totalSteps;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StepProgressDots(currentStep: currentStep, totalSteps: totalSteps),
        SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
