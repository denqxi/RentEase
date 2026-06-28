import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../cubit/registration_cubit.dart';
import '../model/user_role.dart';
import '../widgets/role_option_card.dart';
import '../widgets/step_header.dart';

/// "Join RentEase" — choose a role before starting the form.
class RoleSelectionView extends StatelessWidget {
  const RoleSelectionView({required this.onSignIn, super.key});

  /// Tapped on the "Sign in" link for users who already have an account.
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();
    final state = context.watch<RegistrationCubit>().state;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const StepHeader(
            title: 'Join RentEase',
            subtitle: 'How do you want to use RentEase? You can change this '
                'later.',
          ),
          SizedBox(height: AppSpacing.lg),
          for (final role in UserRole.values) ...<Widget>[
            RoleOptionCard(
              role: role,
              selected: state.data.role == role,
              onTap: () => cubit.selectRole(role),
            ),
            SizedBox(height: AppSpacing.md),
          ],
          const Spacer(),
          AppPrimaryButton(
            label: 'Continue',
            onPressed: state.canContinueFromRole ? cubit.next : null,
          ),
          SizedBox(height: AppSpacing.md),
          Center(
            child: GestureDetector(
              onTap: onSignIn,
              child: Text.rich(
                TextSpan(
                  style: AppTextStyles.link(context),
                  children: <InlineSpan>[
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Sign in',
                      style: AppTextStyles.link(context).copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
