import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../registration/model/user_role.dart';
import '../../domain/entities/auth.dart';
import '../bloc/auth_bloc.dart';
import 'email_verification_screen.dart';

/// Sign-in screen â€” hero building image behind a bottom-anchored white card.
class SignInScreen extends StatefulWidget {
  const SignInScreen({this.onCreateAccount, this.onSignIn, super.key});

  /// Called when the user taps "Create an account".
  final VoidCallback? onCreateAccount;

  /// Called after a successful sign-in, once [AuthBloc] confirms the role.
  final ValueChanged<AppUser>? onSignIn;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _imageFade;
  late final Animation<double> _imageScale;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<Offset> _fieldsSlide;
  late final Animation<Offset> _buttonsSlide;
  late final Animation<Offset> _socialSlide;

  Animation<Offset> _slide(double dy, double begin, double end) =>
      Tween<Offset>(begin: Offset(0, dy), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animCtrl,
          curve: Interval(begin, end, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void initState() {
    super.initState();
    // 8-second staggered entrance: hero scales/fades in, card slides up.
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );
    _imageFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.70, curve: Curves.easeOut),
    );
    _imageScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _cardSlide = _slide(0.35, 0.05, 0.85);
    _cardFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );
    _headerSlide = _slide(0.30, 0.10, 0.80);
    _fieldsSlide = _slide(0.35, 0.20, 0.90);
    _buttonsSlide = _slide(0.40, 0.30, 0.95);
    _socialSlide = _slide(0.45, 0.38, 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      AppRouter.routeObserver.subscribe(this, modalRoute);
    }
    // Warm the image cache to avoid decode latency during the entrance.
    precacheImage(const AssetImage('assets/images/building2.png'), context);
    precacheImage(const AssetImage('assets/images/logo.png'), context);
  }

  @override
  void didPopNext() {
    // Replay the entrance when returning from registration.
    if (mounted) _animCtrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    _animCtrl.dispose();
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

  void _handleSignIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailError = Validators.email(email);
    if (emailError != null) {
      _showError(emailError);
      return;
    }
    if (password.isEmpty) {
      _showError('Enter your password.');
      return;
    }
    context.read<AuthBloc>().add(
          AuthSignInRequested(email: email, password: password),
        );
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();
    final emailError = Validators.email(email);
    if (emailError != null) {
      _showError('Enter your email above first, then tap "Forgot password?".');
      return;
    }
    context.read<AuthBloc>().add(AuthPasswordResetRequested(email: email));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // AuthBloc is app-wide, so this screen also hears events fired by
        // routes pushed on top of it (e.g. the registration flow). Only
        // react while this screen is actually the one on screen.
        if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;

        if (state is AuthAuthenticated) {
          widget.onSignIn?.call(state.user);
        } else if (state is AuthEmailNotVerified) {
          // Send them to the verification screen (resend/check) instead of
          // leaving them stuck on sign-in with no way to resend. Admins
          // never verify email (same rule as the splash routing).
          if (state.user.isAdmin) {
            widget.onSignIn?.call(state.user);
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  EmailVerificationScreen(isOwner: state.user.isOwner),
            ),
          );
        } else if (state is AuthOperationFailure) {
          _showError(state.message);
        } else if (state is AuthSuspended) {
          _showError(AuthBloc.suspendedMessage);
        } else if (state is AuthPasswordResetEmailSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password reset link sent to ${state.email}.')),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: ScaleTransition(
                scale: _imageScale,
                child: FadeTransition(
                  opacity: _imageFade,
                  child: const _SignInBackground(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: RepaintBoundary(
                child: SlideTransition(
                  position: _cardSlide,
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) => _SignInCard(
                  headerSlide: _headerSlide,
                  fieldsSlide: _fieldsSlide,
                  buttonsSlide: _buttonsSlide,
                  socialSlide: _socialSlide,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  rememberMe: _rememberMe,
                  obscurePassword: _obscurePassword,
                  isLoading: state is AuthLoading,
                  isSuspended: state is AuthSuspended,
                  onRememberMeChanged: (v) =>
                      setState(() => _rememberMe = v ?? false),
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onCreateAccount: widget.onCreateAccount,
                  onSignIn: _handleSignIn,
                  onForgotPassword: _handleForgotPassword,
                ),
                    ),
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
            colors: [AppColors.primary, AppColors.accent, context.appColors.ink],
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
    required this.headerSlide,
    required this.fieldsSlide,
    required this.buttonsSlide,
    required this.socialSlide,
    this.isLoading = false,
    this.isSuspended = false,
    this.onCreateAccount,
    this.onSignIn,
    this.onForgotPassword,
  });

  /// The account was suspended by an admin: show a persistent notice (the
  /// snackbar alone is missed when this is the first screen after app start).
  final bool isSuspended;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final bool isLoading;
  final Animation<Offset> headerSlide;
  final Animation<Offset> fieldsSlide;
  final Animation<Offset> buttonsSlide;
  final Animation<Offset> socialSlide;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onSignIn;
  final VoidCallback? onForgotPassword;

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
            color: AppColors.ink.withValues(alpha: 0.09),
            blurRadius: 24,
            offset: const Offset(0, -6),
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
              SlideTransition(
                position: headerSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SignInLogoRow(),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Sign In',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Continue your rental journey with RentEase.',
                      style: AppTextStyles.body(context).copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSuspended) ...[
                SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadii.field),
                    border: Border.all(color: AppColors.destructive, width: 0.5),
                  ),
                  child: Text(
                    AuthBloc.suspendedMessage,
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(color: AppColors.destructive),
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.lg),
              SlideTransition(
                position: fieldsSlide,
                child: _SignInFields(
                  emailController: emailController,
                  passwordController: passwordController,
                  obscurePassword: obscurePassword,
                  rememberMe: rememberMe,
                  onRememberMeChanged: onRememberMeChanged,
                  onTogglePassword: onTogglePassword,
                  onForgotPassword: onForgotPassword,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              SlideTransition(
                position: buttonsSlide,
                child: AppPrimaryButton(
                  label: isLoading ? 'Signing in\u2026' : 'Sign In',
                  onPressed: isLoading ? null : (onSignIn ?? () {}),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              SlideTransition(
                position: socialSlide,
                child: Column(
                  children: [
                    const _OrDivider(),
                    SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Expanded(child: _GoogleButton()),
                        SizedBox(width: AppSpacing.sm),
                        const Expanded(child: _GuestButton()),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _CreateAccountRow(onCreateAccount: onCreateAccount),
                  ],
                ),
              ),
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
    this.onForgotPassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Email address'),
        SizedBox(height: AppSpacing.sm),
        _AuthTextField(
          controller: emailController,
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: AppSpacing.md),
        const _FieldLabel(label: 'Password'),
        SizedBox(height: AppSpacing.sm),
        _AuthTextField(
          controller: passwordController,
          hintText: 'Enter your password',
          obscureText: obscurePassword,
          suffixIcon: Semantics(
            button: true,
            label: obscurePassword ? 'Show password' : 'Hide password',
            child: GestureDetector(
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
        ),
        SizedBox(height: AppSpacing.md),
        _RememberForgotRow(
          rememberMe: rememberMe,
          onChanged: onRememberMeChanged,
          onForgotPassword: onForgotPassword,
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
    this.onForgotPassword,
  });

  final bool rememberMe;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onForgotPassword;

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
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
          onTap: onForgotPassword,
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
              'Google',
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

/// Browse without an account — no Firebase sign-in, so MainShell runs
/// HomeCubit.guest() and gates saving/inquiries/profile behind
/// GuestAccessSheet. Styled as a sibling of [_GoogleButton] under
/// "or continue with".
class _GuestButton extends StatelessWidget {
  const _GuestButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.fieldHeight,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.tenantHome,
          (_) => false,
          arguments: UserRole.guest,
        ),
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
            Image.asset(
              'assets/images/guesticon.png',
              width: 20,
              height: 20,
              errorBuilder: (_, _, _) => Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: context.appColors.textPrimary,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Guest',
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
    canvas.drawPath(blue, fill..color = AppColors.googleBlue);
    canvas.drawPath(green, fill..color = AppColors.googleGreen);
    canvas.drawPath(yellow, fill..color = AppColors.googleYellow);
    canvas.drawPath(red, fill..color = AppColors.googleRed);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
