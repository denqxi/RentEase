import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../cubit/registration_cubit.dart';
import '../model/match_result.dart';
import '../model/user_role.dart';
import '../widgets/match_card.dart';

/// "You're all set!" — confirmation shown once registration completes.
class SuccessView extends StatelessWidget {
  const SuccessView({required this.onExplore, super.key});

  /// Tapped on "Explore RentEase".
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();
    final role = context.watch<RegistrationCubit>().state.data.role;
    final isLandlord = role == UserRole.landlord;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        children: <Widget>[
          const Spacer(),
          const _SuccessBadge(),
          SizedBox(height: AppSpacing.lg),
          Text("You're all set!", style: AppTextStyles.heading(context)),
          SizedBox(height: AppSpacing.sm),
          Text(
            isLandlord
                ? 'Your listing is live. We found tenants that fit your '
                    'requirements.'
                : 'Your tenant profile is ready. Here are homes matched to '
                    'your preferences.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(context),
          ),
          SizedBox(height: AppSpacing.lg),
          MatchCard(
            match: isLandlord
                ? MatchResult.landlordSample
                : MatchResult.tenantSample,
          ),
          const Spacer(),
          AppPrimaryButton(label: 'Explore RentEase', onPressed: onExplore),
          SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: cubit.restart,
            child: Text(
              'Back to start',
              style: AppTextStyles.link(context).copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
