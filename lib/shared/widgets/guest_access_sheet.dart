import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
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

  // Navigation below deliberately uses the [NavigatorState] captured before
  // the sheet closes, plus each pushed route's own builder context — never
  // the sheet's context, which is dead once the sheet is popped (callbacks
  // fired later from it, e.g. registration's back/"Sign in", silently fail).

  /// Pushes the sign-in screen over the guest shell and, for "Create an
  /// account", the registration flow on top of that — the same stack
  /// app.dart builds — so registration's back arrow and "Already have an
  /// account? Sign in" both land on sign-in, and backing out of sign-in
  /// returns to guest browsing.
  static void _openSignIn(
    NavigatorState navigator, {
    bool thenCreateAccount = false,
  }) {
    navigator.push(
      MaterialPageRoute<void>(
        builder: (signInContext) => SignInScreen(
          onSignIn: (user) =>
              Navigator.of(signInContext).pushNamedAndRemoveUntil(
                user.isOwner ? AppRouter.landlordHome : AppRouter.tenantHome,
                (_) => false,
              ),
          onCreateAccount: () => _openRegistration(Navigator.of(signInContext)),
        ),
      ),
    );
    if (thenCreateAccount) _openRegistration(navigator);
  }

  static void _openRegistration(NavigatorState navigator) {
    navigator.push(
      MaterialPageRoute<void>(
        builder: (registrationContext) => RegistrationFlowScreen(
          // Matches app.dart's _SignInEntry._pushOnboarding — account
          // creation always goes through email verification before
          // onboarding.
          onComplete: (role) =>
              Navigator.of(registrationContext).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => EmailVerificationScreen(
                    isOwner: role == UserRole.landlord,
                  ),
                ),
                (_) => false,
              ),
          onSignIn: () => Navigator.of(registrationContext).pop(),
        ),
      ),
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
                  color: AppColors.guestWarnFill,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.guestWarnIcon,
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
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  _openSignIn(navigator, thenCreateAccount: true);
                },
              ),
              SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Sign in',
                isOutlined: true,
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  _openSignIn(navigator);
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
