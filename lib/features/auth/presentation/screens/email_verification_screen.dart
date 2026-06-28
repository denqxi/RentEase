import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../features/registration/widgets/registration_app_bar.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({this.isOwner = false, super.key});

  final bool isOwner;

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
                      onTap: () {},
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
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  isOwner ? AppRouter.documentUpload : AppRouter.hardConstraints,
                  (_) => false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
