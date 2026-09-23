import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../features/registration/widgets/registration_app_bar.dart';
import '../bloc/auth_bloc.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({this.isOwner = false, super.key});

  final bool isOwner;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.destructive : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            widget.isOwner ? AppRouter.documentUpload : AppRouter.hardConstraints,
            (_) => false,
          );
        } else if (state is AuthOperationFailure) {
          _showMessage(state.message, isError: true);
        }
      },
      child: _EmailVerificationBody(
        isOwner: widget.isOwner,
        onResend: () {
          context
              .read<AuthBloc>()
              .add(const AuthEmailVerificationResendRequested());
          _showMessage('Verification email re-sent.');
        },
        onContinue: () => context
            .read<AuthBloc>()
            .add(const AuthEmailVerificationCheckRequested()),
      ),
    );
  }
}

class _EmailVerificationBody extends StatelessWidget {
  const _EmailVerificationBody({
    required this.isOwner,
    required this.onResend,
    required this.onContinue,
  });

  final bool isOwner;
  final VoidCallback onResend;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegistrationAppBar(
                onBack: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        color: AppColors.accent,
                        size: 40,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    Text(
                      'Check your email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'We sent a verification link to your email address. Click the link to activate your account.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(context).copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    GestureDetector(
                      onTap: onResend,
                      child: Text(
                        'Resend email',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      "Check your spam folder if you don't see it.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption(context).copyWith(
                        color: context.appColors.hint,
                      ),
                    ),
                  ],
                ),
              ),
              AppPrimaryButton(
                label: 'Continue',
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
