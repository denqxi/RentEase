import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/card_over_hero_layout.dart';
import 'email_verification_screen.dart';
import 'auth_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({this.isOwner = false, super.key});

  final bool isOwner;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CardOverHeroLayout(
      hero: const HeroPlaceholder(imageAsset: 'assets/images/building2.png'),
      cardContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create account',
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
            widget.isOwner
                ? 'Set up your owner account to list your property.'
                : 'Set up your account to find your next home.',
            style: AppTextStyles.body(context),
          ),
          SizedBox(height: AppSpacing.lg),
          LabelledField(
            label: 'Full name',
            child: AppTextField(controller: _nameController, hintText: 'Juan dela Cruz'),
          ),
          SizedBox(height: AppSpacing.md),
          LabelledField(
            label: 'Email',
            child: AppTextField(
              controller: _emailController,
              hintText: 'you@email.com',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          LabelledField(
            label: 'Phone number',
            child: AppTextField(
              controller: _phoneController,
              hintText: '09XX XXX XXXX',
              keyboardType: TextInputType.phone,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          LabelledField(
            label: 'Password',
            child: AppTextField(
              controller: _passwordController,
              hintText: 'At least 8 characters',
              obscureText: _obscurePassword,
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: context.appColors.hint,
                  size: 20,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          LabelledField(
            label: 'Confirm password',
            child: AppTextField(
              controller: _confirmController,
              hintText: 'Re-enter password',
              obscureText: _obscureConfirm,
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                child: Icon(
                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: context.appColors.hint,
                  size: 20,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Sign up',
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => EmailVerificationScreen(isOwner: widget.isOwner),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Center(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.label(context).copyWith(
                  color: context.appColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
                      ),
                      child: Text(
                        'Log in',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
