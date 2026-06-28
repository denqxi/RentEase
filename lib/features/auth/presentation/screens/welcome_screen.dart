import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/card_over_hero_layout.dart';
import 'role_selection_screen.dart';
import 'auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CardOverHeroLayout(
      hero: const HeroPlaceholder(imageAsset: 'assets/images/building2.png'),
      cardContent: _WelcomeCard(
        onGetStarted: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const RoleSelectionScreen()),
        ),
        onLogIn: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onGetStarted, required this.onLogIn});

  final VoidCallback onGetStarted;
  final VoidCallback onLogIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Image.asset(
            'assets/images/logo.png',
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_work_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 6),
                Text(
                  'RentEase',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          'Welcome to RentEase',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: context.appColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'Find the perfect boarding house match near your school or work.',
          style: AppTextStyles.body(context),
        ),
        SizedBox(height: AppSpacing.xl),
        AppButton(label: 'Get Started', onPressed: onGetStarted),
        SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Log In',
          onPressed: onLogIn,
          variant: AppButtonVariant.outline,
        ),
        SizedBox(height: AppSpacing.lg),
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.caption(context),
              children: [
                const TextSpan(text: 'By continuing you agree to our '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Terms',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ' and '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
