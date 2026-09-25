import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../model/match_result.dart';
import '../widgets/match_card.dart';

/// "You're all set!" confirmation screen shown after finding matches / verification.
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({
    this.isOwner = false,
    this.onExplore,
    super.key,
  });

  final bool isOwner;
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: <Widget>[
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: AppColors.onInk, size: 32),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text("You're all set!", style: AppTextStyles.heading(context)),
              SizedBox(height: AppSpacing.sm),
              Text(
                isOwner
                    ? 'Your listing is live. We found tenants that fit your requirements.'
                    : 'Your tenant profile is ready. Here are homes matched to your preferences.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context),
              ),
              SizedBox(height: AppSpacing.lg),
              MatchCard(
                match: isOwner
                    ? MatchResult.landlordSample
                    : MatchResult.tenantSample,
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'Explore RentEase',
                onPressed: onExplore ??
                    () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        isOwner ? AppRouter.landlordHome : AppRouter.tenantHome,
                        (_) => false,
                      );
                    },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
