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
              SizedBox(height: AppSpacing.lg),
              Text('Sign in', style: AppTextStyles.title(context)),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Welcome back! continue your rental journey with RentEase.',
                style: AppTextStyles.body(context),
              ),
              SizedBox(height: AppSpacing.lg),
              _SignInFields(
                emailController: emailController,
                passwordController: passwordController,
                obscurePassword: obscurePassword,
                rememberMe: rememberMe,
                onRememberMeChanged: onRememberMeChanged,
                onTogglePassword: onTogglePassword,
              ),
              SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(label: 'Sign In', onPressed: onSignIn ?? () {}),
              SizedBox(height: AppSpacing.lg),
              const _OrDivider(),
              SizedBox(height: AppSpacing.lg),
              const _GoogleButton(),
              SizedBox(height: AppSpacing.md),
              _CreateAccountRow(onCreateAccount: onCreateAccount),
              SizedBox(height: AppSpacing.md),
              const _DemoModeRow(),
              SizedBox(height: AppSpacing.lg),
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
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_work_rounded, color: AppColors.primary, size: 22),
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
              child: CustomPaint(painter: _GoogleLogoPainter()),
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

class _DemoModeRow extends StatelessWidget {
  const _DemoModeRow();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => _showDemoModeSheet(context),
        child: Text(
          'Try Demo Mode',
          style: AppTextStyles.label(context).copyWith(
            color: context.appColors.textSecondary,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  void _showDemoModeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Try Demo Mode', style: AppTextStyles.title(sheetContext)),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Jump straight into the app with sample data. '
                'Nothing you do here is saved permanently.',
                style: AppTextStyles.body(sheetContext),
              ),
              SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Continue as Demo Tenant',
                onPressed: () => Navigator.of(sheetContext)
                    .pushNamedAndRemoveUntil(AppRouter.tenantHome, (_) => false),
              ),
              SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Continue as Demo Owner',
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.of(sheetContext)
                    .pushNamedAndRemoveUntil(AppRouter.landlordHome, (_) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Painters â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Paints Google's official multi-color "G" mark, traced from Google's
/// brand-guideline SVG (24x24 viewBox) rather than an approximated shape,
/// so the sign-in button matches the real logo.
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    // Blue segment.
    final blue = Path()
      ..moveTo(22.56, 12.25)
      ..relativeCubicTo(0, -0.78, -0.07, -1.53, -0.2, -2.25)
      ..lineTo(12, 10)
      ..relativeLineTo(0, 4.26)
      ..relativeLineTo(5.92, 0)
      ..relativeCubicTo(-0.26, 1.37, -1.04, 2.53, -2.21, 3.31)
      ..relativeLineTo(0, 2.77)
      ..relativeLineTo(3.57, 0)
      ..relativeCubicTo(2.08, -1.92, 3.28, -4.74, 3.28, -8.09)
      ..close();

    // Green segment.
    final green = Path()
      ..moveTo(12, 23)
      ..relativeCubicTo(2.97, 0, 5.46, -0.98, 7.28, -2.66)
      ..relativeLineTo(-3.57, -2.77)
      ..relativeCubicTo(-0.98, 0.66, -2.23, 1.06, -3.71, 1.06)
      ..relativeCubicTo(-2.86, 0, -5.29, -1.93, -6.16, -4.53)
      ..lineTo(2.18, 14.09)
      ..relativeLineTo(0, 2.84)
      ..cubicTo(3.99, 20.53, 7.7, 23, 12, 23)
      ..close();

    // Yellow segment (includes one SVG smooth-cubic "s" reflected manually).
    final yellow = Path()
      ..moveTo(5.84, 14.09)
      ..relativeCubicTo(-0.22, -0.66, -0.35, -1.36, -0.35, -2.09)
      ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
      ..lineTo(5.84, 7.07)
      ..lineTo(2.18, 7.07)
      ..cubicTo(1.43, 8.55, 1, 10.22, 1, 12)
      ..cubicTo(1, 13.78, 1.43, 15.45, 2.18, 16.93)
      ..relativeLineTo(2.85, -2.22)
      ..relativeLineTo(0.81, -0.62)
      ..close();

    // Red segment.
    final red = Path()
      ..moveTo(12, 5.38)
      ..relativeCubicTo(1.62, 0, 3.06, 0.56, 4.21, 1.64)
      ..relativeLineTo(3.15, -3.15)
      ..cubicTo(17.45, 2.09, 14.97, 1, 12, 1)
      ..cubicTo(7.7, 1, 3.99, 3.47, 2.18, 7.07)
      ..relativeLineTo(3.66, 2.84)
      ..relativeCubicTo(0.87, -2.6, 3.3, -4.53, 6.16, -4.53)
      ..close();

    final fill = Paint()..style = PaintingStyle.fill;
    canvas.drawPath(blue, fill..color = const Color(0xFF4285F4));
    canvas.drawPath(green, fill..color = const Color(0xFF34A853));
    canvas.drawPath(yellow, fill..color = const Color(0xFFFBBC05));
    canvas.drawPath(red, fill..color = const Color(0xFFEA4335));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
