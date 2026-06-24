import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

/// Primary action button plus the secondary text link at the bottom of the
/// onboarding card.
///
/// The labels and callbacks differ on the last page ("Get Started" /
/// "I already have an account") versus earlier pages ("Next" / "Skip").
class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({
    required this.isLastPage,
    required this.onPrimary,
    required this.onSecondary,
    super.key,
  });

  /// Whether the final page is showing.
  final bool isLastPage;

  /// Tapped when the primary ("Next" / "Get Started") button is pressed.
  final VoidCallback onPrimary;

  /// Tapped when the secondary ("Skip" / "I already have an account") link is
  /// pressed.
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppPrimaryButton(
          label: isLastPage ? 'Get Started' : 'Next',
          onPressed: onPrimary,
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: onSecondary,
          child: Text(
            isLastPage ? 'I already have an account' : 'Skip',
            style: isLastPage
                ? AppTextStyles.link.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  )
                : AppTextStyles.link,
          ),
        ),
      ],
    );
  }
}
