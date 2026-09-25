import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/card_over_hero_layout.dart';
import 'auth_screen.dart';
import '../../../../core/router/app_router.dart';
import 'terms_and_conditions_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({this.isOwner = false, super.key});

  final bool isOwner;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.05, 0.85, curve: Curves.easeOutCubic),
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.70, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
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
      cardContent: RepaintBoundary(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: context.appColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                    children: const [
                      TextSpan(text: 'Join '),
                      TextSpan(
                        text: 'RentEase',
                        style: TextStyle(
                          color: Color(0xFF1ABCCE),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Select how you want to use RentEase to personalize your experience.',
                  style: AppTextStyles.body(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                LabelledField(
                  label: 'Full name',
                  child: AppTextField(
                    controller: _nameController,
                    hintText: 'Juan dela Cruz',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabelledField(
                  label: 'Email',
                  child: AppTextField(
                    controller: _emailController,
                    hintText: 'you@email.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabelledField(
                  label: 'Phone number',
                  child: AppTextField(
                    controller: _phoneController,
                    hintText: '09XX XXX XXXX',
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabelledField(
                  label: 'Password',
                  child: AppTextField(
                    controller: _passwordController,
                    hintText: 'At least 8 characters',
                    obscureText: _obscurePassword,
                    suffixIcon: GestureDetector(
                      onTap: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: context.appColors.hint,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LabelledField(
                  label: 'Confirm password',
                  child: AppTextField(
                    controller: _confirmController,
                    hintText: 'Re-enter password',
                    obscureText: _obscureConfirm,
                    suffixIcon: GestureDetector(
                      onTap: () => setState(
                        () => _obscureConfirm = !_obscureConfirm,
                      ),
                      child: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: context.appColors.hint,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) => setState(
                          () => _agreedToTerms = value ?? false,
                        ),
                        activeColor: AppColors.accent,
                        side: BorderSide(
                          color: context.appColors.fieldBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                          () => _agreedToTerms = !_agreedToTerms,
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.label(context).copyWith(
                              color: context.appColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const TermsAndConditionsScreen(),
                                    ),
                                  ),
                                  child: const Text(
                                    'Terms and Agreement',
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
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Sign up',
                  onPressed: _agreedToTerms
                      ? () => Navigator.of(context).pushNamed(
                            widget.isOwner
                                ? AppRouter.documentUpload
                                : AppRouter.hardConstraints,
                          )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
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
                              MaterialPageRoute<void>(
                                builder: (_) => const SignInScreen(),
                              ),
                            ),
                            child: const Text(
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
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
