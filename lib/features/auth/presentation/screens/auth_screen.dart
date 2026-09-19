import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';


/// Sign-in screen â€” hero building image behind a bottom-anchored white card.
class SignInScreen extends StatefulWidget {
  const SignInScreen({this.onCreateAccount, this.onSignIn, super.key});

  /// Called when the user taps "Create an account".
  final VoidCallback? onCreateAccount;

  /// Called when the user taps "Sign In".
  final VoidCallback? onSignIn;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.destructive,
      ),
    );
  }

  /// Authenticates against the in-memory account list (seeded demo accounts
  /// plus any created via signup this session) and routes by role.
  void _handleSignIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Enter your email and password.');
      return;
    }
    final account = MockData.findAccount(email);
    if (account == null) {
      _showError('No account found for that email. '
          'Create one or use Demo Mode.');
      return;
    }
    if (account['password'] != password) {
      _showError('Incorrect password. Please try again.');
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      account['role'] == 'owner'
          ? AppRouter.landlordHome
          : AppRouter.tenantHome,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SignInBackground(),
          Align(
            alignment: Alignment.bottomCenter,
            child: _SignInCard(
              emailController: _emailController,
              passwordController: _passwordController,
              rememberMe: _rememberMe,
              obscurePassword: _obscurePassword,
              onRememberMeChanged: (v) =>
                  setState(() => _rememberMe = v ?? false),
              onTogglePassword: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onCreateAccount: widget.onCreateAccount,
              onSignIn: _handleSignIn,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Background â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SignInBackground extends StatelessWidget {
  const _SignInBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/building2.png',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, _, _) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF0E8FA0), context.appColors.ink],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SignInCard extends StatelessWidget {
  const _SignInCard({
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.onRememberMeChanged,
    required this.onTogglePassword,
    this.onCreateAccount,
    this.onSignIn,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.73,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          0,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SignInLogoRow(),
              SizedBox(height: AppSpacing.md),
              Text('Sign in', style: AppTextStyles.title(context)),
              SizedBox(height: 4),
              Text(
                'Welcome back! continue your rental journey with RentEase.',
                style: AppTextStyles.body(context),
              ),
              SizedBox(height: AppSpacing.md),
              _SignInFields(
                emailController: emailController,
                passwordController: passwordController,
                obscurePassword: obscurePassword,
                rememberMe: rememberMe,
                onRememberMeChanged: onRememberMeChanged,
                onTogglePassword: onTogglePassword,
              ),
              SizedBox(height: AppSpacing.md),
              AppPrimaryButton(label: 'Sign In', onPressed: onSignIn ?? () {}),
              SizedBox(height: AppSpacing.sm),
              _CreateAccountRow(onCreateAccount: onCreateAccount),
              SizedBox(height: AppSpacing.md),
              const _OrDivider(),
              SizedBox(height: AppSpacing.md),
              const _GoogleButton(),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Logo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SignInLogoRow extends StatelessWidget {
  const _SignInLogoRow();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onLongPress: () =>
            Navigator.of(context).pushNamed(AppRouter.adminLogin),
        child: Image.asset(
          'assets/images/logo.png',
          height: 46,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_work_rounded, color: AppColors.primary, size: 26),
              SizedBox(width: 6),
              Text(
                'RentEase',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Form fields â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SignInFields extends StatelessWidget {
  const _SignInFields({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onTogglePassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Email'),
        SizedBox(height: AppSpacing.sm),
        _AuthTextField(
          controller: emailController,
          hintText: 'you@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: AppSpacing.md),
        const _FieldLabel(label: 'Password'),
        SizedBox(height: AppSpacing.sm),
        _AuthTextField(
          controller: passwordController,
          hintText: 'Your password',
          obscureText: obscurePassword,
          suffixIcon: GestureDetector(
            onTap: onTogglePassword,
            child: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: context.appColors.hint,
              size: 20,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        _RememberForgotRow(
          rememberMe: rememberMe,
          onChanged: onRememberMeChanged,
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.label(context).copyWith(color: context.appColors.textSecondary),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: AppTextStyles.field(context),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.field(context).copyWith(color: context.appColors.hint),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        filled: true,
        fillColor: context.appColors.fieldFill,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: context.appColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _RememberForgotRow extends StatelessWidget {
  const _RememberForgotRow({
    required this.rememberMe,
    required this.onChanged,
  });

  final bool rememberMe;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: rememberMe,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: BorderSide(color: context.appColors.hint, width: 1.5),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          'Remember me',
          style: AppTextStyles.label(context).copyWith(
            color: context.appColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {},
          child: Text(
            'Forgot password?',
            style: AppTextStyles.label(context).copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€ Divider & Social â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: context.appColors.fieldBorder, thickness: 1),
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'or continue with',
            style: AppTextStyles.label(context).copyWith(
              color: context.appColors.hint,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: context.appColors.fieldBorder, thickness: 1),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.fieldHeight,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.appColors.fieldBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          backgroundColor: context.appColors.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Image.asset(
                'assets/images/google.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Continue with Google',
              style: AppTextStyles.body(context).copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Footer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CreateAccountRow extends StatelessWidget {
  const _CreateAccountRow({this.onCreateAccount});

  final VoidCallback? onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.label(context).copyWith(
            color: context.appColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          children: [
            const TextSpan(text: 'New to RentEase? '),
            WidgetSpan(
              child: GestureDetector(
                onTap: onCreateAccount,
                child: Text(
                  'Create an account',
                  style: AppTextStyles.label(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

