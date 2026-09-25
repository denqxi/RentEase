import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/registration/view/registration_flow_screen.dart';
import '../../features/registration/model/user_role.dart';
import 'app_button.dart';

/// Reusable bottom sheet shown when a guest tries a restricted action.
class GuestAccessSheet extends StatelessWidget {
  const GuestAccessSheet({super.key});

  /// Presents the guest access sheet modally.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GuestAccessSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.fieldBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFDD6B20),
                  size: 28,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Create an account to unlock',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.appColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Sign up or sign in to save listings, send inquiries, '
                'view your match scores, and manage your profile.',
                style: AppTextStyles.body(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Create an account',
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RegistrationFlowScreen(
                        onComplete: (role) => Navigator.of(context)
                            .pushNamed(
                          role == UserRole.landlord
                              ? AppRouter.documentUpload
                              : AppRouter.hardConstraints,
                        ),
                        onSignIn: () => Navigator.of(context).pop(),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Sign in',
                isOutlined: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SignInScreen(
                        onSignIn: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil(
                          AppRouter.roleSelection,
                          (_) => false,
                        ),
                        onCreateAccount: () => Navigator.of(context).pop(),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Keep browsing as Guest',
                  style: AppTextStyles.link(context).copyWith(
                    color: context.appColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
