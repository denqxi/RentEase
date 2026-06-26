import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../shell/view/main_shell.dart';
import '../../tenant_onboarding/view/hard_constraints_screen.dart';
import '../cubit/registration_cubit.dart';

/// Shown immediately after account creation — prompts the user to verify
/// the email address they entered before continuing the flow.
class CheckEmailView extends StatelessWidget {
  const CheckEmailView({super.key});

  @override
  Widget build(BuildContext context) {
    final email = context.watch<RegistrationCubit>().state.data.email;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          const Spacer(),

          // Icon
          Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryMid,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text('Check your email', style: AppTextStyles.heading),

          const SizedBox(height: AppSpacing.sm),

          Text(
            email.isNotEmpty
                ? 'We sent a verification link to\n$email'
                : 'We sent a verification link to your email address.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Click the link in the email to verify your account\nbefore continuing.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),

          const Spacer(),

          AppPrimaryButton(
            label: 'I\'ve verified my email',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HardConstraintsScreen(
                  onComplete: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                        builder: (_) => const MainShell()),
                    (route) => false,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          TextButton(
            onPressed: () {},
            child: Text(
              'Resend email',
              style: AppTextStyles.link.copyWith(
                color: AppColors.primaryMid,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
