import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/url_opener.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/registration_cubit.dart';

/// Shown immediately after account creation — prompts the user to verify
/// the email address they entered before continuing the flow.
class CheckEmailView extends StatefulWidget {
  const CheckEmailView({super.key});

  @override
  State<CheckEmailView> createState() => _CheckEmailViewState();
}

class _CheckEmailViewState extends State<CheckEmailView> {
  // Anti-spam countdown: 45s initially when screen opens and on resend.
  int _resendCountdown = 45;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown(45);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = seconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        setState(() => _resendCountdown = 0);
        timer.cancel();
      }
    });
  }

  void _resend() {
    if (_resendCountdown > 0) return;
    context
        .read<AuthBloc>()
        .add(const AuthEmailVerificationResendRequested());
    _startCountdown(45);
  }

  Future<void> _handleOpenEmailApp() async {
    final opened = await openEmailApp();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open email app. Please check your inbox.'),
        ),
      );
    }
  }

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
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread_rounded,
                color: AppColors.onInk,
                size: 30,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text('Check your email', style: AppTextStyles.heading(context)),

          const SizedBox(height: AppSpacing.sm),

          Text(
            email.isNotEmpty
                ? 'We sent a verification link to\n$email'
                : 'We sent a verification link to your email address.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(context),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Click the link in the email to verify your account\nbefore continuing.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),

          const Spacer(),

          AppPrimaryButton(
            label: 'Open email app',
            onPressed: _handleOpenEmailApp,
          ),

          const SizedBox(height: AppSpacing.md),

          GestureDetector(
            onTap: _resendCountdown == 0 ? _resend : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xs,
                horizontal: AppSpacing.sm,
              ),
              child: Text(
                _resendCountdown > 0
                    ? 'Resend email [${_resendCountdown}s]'
                    : 'Resend email',
                style: _resendCountdown > 0
                    ? AppTextStyles.body(context).copyWith(
                        color: context.appColors.hint,
                        fontWeight: FontWeight.w600,
                      )
                    : AppTextStyles.link(context).copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
