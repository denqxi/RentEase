import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../registration/model/user_role.dart';
import '../../../registration/view/registration_flow_screen.dart';

/// Sign-in screen — hero building image with 8-second scale-up and fade,
/// behind a bottom-anchored white card with slide-up animations for all components.
///
/// Performance-optimized with asset pre-caching, [RepaintBoundary] isolation,
/// and const widget instantiations for 60/120fps smooth rendering.
class SignInScreen extends StatefulWidget {
  const SignInScreen({this.onCreateAccount, this.onSignIn, super.key});

  /// Called when the user taps "Create an account".
  final VoidCallback? onCreateAccount;

  /// Called when the user taps "Sign In".
  final VoidCallback? onSignIn;

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

  // Background image: Scale up and Fade animation (8s)
  late final Animation<double> _imageFade;
  late final Animation<double> _imageScale;

  // White container and components: Slide up and Fade animation (8s)
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  // Staggered slide animations for components inside the white container
  late final Animation<Offset> _headerSlide;
  late final Animation<Offset> _fieldsSlide;
  late final Animation<Offset> _buttonsSlide;
  late final Animation<Offset> _socialSlide;

  @override
  void initState() {
    super.initState();

    // 8-second animation controller
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

    // Image: Scale up (0.88 -> 1.0) and Fade in
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

    // White container slide-up & fade
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.05, 0.85, curve: Curves.easeOutCubic),
    ));
    _cardFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );

    // Staggered component slide-ups inside the white container
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.30),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.10, 0.80, curve: Curves.easeOutCubic),
    ));

    _fieldsSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.20, 0.90, curve: Curves.easeOutCubic),
    ));

    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.40),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.30, 0.95, curve: Curves.easeOutCubic),
    ));

    _socialSlide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.38, 1.0, curve: Curves.easeOutCubic),
    ));

    // Wait for route transition to settle then start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animCtrl.forward();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      AppRouter.routeObserver.subscribe(this, modalRoute);
    }
    // Warm up image assets in memory to eliminate decoding latency
    precacheImage(const AssetImage('assets/images/building2.png'), context);
    precacheImage(const AssetImage('assets/images/google.png'), context);
    precacheImage(const AssetImage('assets/images/logo.png'), context);
  }

  @override
  void didPopNext() {
    // Replay full 8s animation when popping back from registration/signup
    if (mounted) {
      _animCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleCreateAccount() {
    if (widget.onCreateAccount != null) {
      widget.onCreateAccount!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RegistrationFlowScreen(
            onComplete: (role) => Navigator.of(context).pushNamed(
              role == UserRole.landlord
                  ? AppRouter.documentUpload
                  : AppRouter.hardConstraints,
            ),
            onSignIn: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
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
          // Background image with scale-up and fade animation
          RepaintBoundary(
            child: ScaleTransition(
              scale: _imageScale,
              child: FadeTransition(
                opacity: _imageFade,
                child: const _SignInBackground(),
              ),
            ),
          ),

          // Bottom-anchored white card with slide-up animations for all components
          Align(
            alignment: Alignment.bottomCenter,
            child: RepaintBoundary(
              child: SlideTransition(
                position: _cardSlide,
                child: FadeTransition(
                  opacity: _cardFade,
                  child: _SignInCard(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    rememberMe: _rememberMe,
                    obscurePassword: _obscurePassword,
                    headerSlide: _headerSlide,
                    fieldsSlide: _fieldsSlide,
                    buttonsSlide: _buttonsSlide,
                    socialSlide: _socialSlide,
                    onRememberMeChanged: (v) =>
                        setState(() => _rememberMe = v ?? false),
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onCreateAccount: _handleCreateAccount,
                    onSignIn: _handleSignIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background ─────────────────────────────────────────────────────────────

class _SignInBackground extends StatelessWidget {
  const _SignInBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/building2.png',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              const Color(0xFF0E8FA0),
              context.appColors.ink,
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card ───────────────────────────────────────────────────────────────────

class _SignInCard extends StatelessWidget {
  const _SignInCard({
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.headerSlide,
    required this.fieldsSlide,
    required this.buttonsSlide,
    required this.socialSlide,
    required this.onRememberMeChanged,
    required this.onTogglePassword,
    this.onCreateAccount,
    this.onSignIn,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final Animation<Offset> headerSlide;
  final Animation<Offset> fieldsSlide;
  final Animation<Offset> buttonsSlide;
  final Animation<Offset> socialSlide;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
        boxShadow: const [
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
          AppSpacing.lg,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header component (Logo, Title, Welcome text) with slide-up
              SlideTransition(
                position: headerSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SignInLogoRow(),
                    const SizedBox(height: AppSpacing.md),
                    Text('Sign in', style: AppTextStyles.title(context)),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome back! continue your rental journey with RentEase.',
                      style: AppTextStyles.body(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Form fields component (Email, Password, Remember me) with slide-up
              SlideTransition(
                position: fieldsSlide,
                child: _SignInFields(
                  emailController: emailController,
                  passwordController: passwordController,
                  obscurePassword: obscurePassword,
                  rememberMe: rememberMe,
                  onRememberMeChanged: onRememberMeChanged,
                  onTogglePassword: onTogglePassword,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Buttons component (Sign In, Create account) with slide-up
              SlideTransition(
                position: buttonsSlide,
                child: Column(
                  children: [
                    AppPrimaryButton(
                      label: 'Sign In',
                      onPressed: onSignIn ?? () {},
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CreateAccountRow(onCreateAccount: onCreateAccount),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Social divider and Google button with slide-up
              SlideTransition(
                position: socialSlide,
                child: const Column(
                  children: [
                    _OrDivider(),
                    SizedBox(height: AppSpacing.md),
                    _GoogleButton(),
                    SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Logo ───────────────────────────────────────────────────────────────────

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
          height: 34,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home_work_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 6),
              Text(
                'RentEase',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 19,
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

// ─── Form fields ────────────────────────────────────────────────────────────

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
        const SizedBox(height: AppSpacing.sm),
        _AuthTextField(
          controller: emailController,
          hintText: 'you@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel(label: 'Password'),
        const SizedBox(height: AppSpacing.sm),
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
        const SizedBox(height: AppSpacing.md),
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
      style: AppTextStyles.label(context).copyWith(
        color: context.appColors.textSecondary,
      ),
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
        hintStyle: AppTextStyles.field(context).copyWith(
          color: context.appColors.hint,
        ),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
        const SizedBox(width: AppSpacing.sm),
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
            style: AppTextStyles.label(context).copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Divider & Social ───────────────────────────────────────────────────────

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
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.pressed)) {
              return context.appColors.fieldFill;
            }
            if (states.contains(WidgetState.hovered)) {
              return Color.alphaBlend(
                context.appColors.fieldFill.withValues(alpha: 0.75),
                context.appColors.surface,
              );
            }
            return context.appColors.surface;
          }),
          side: WidgetStateProperty.resolveWith<BorderSide>((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return BorderSide(
                color: context.appColors.textSecondary.withValues(alpha: 0.45),
                width: 1.2,
              );
            }
            return BorderSide(color: context.appColors.fieldBorder);
          }),
          elevation: WidgetStateProperty.resolveWith<double>((states) {
            if (states.contains(WidgetState.hovered)) return 1.5;
            return 0.0;
          }),
          overlayColor: WidgetStateProperty.all(
            context.appColors.fieldFill.withValues(alpha: 0.5),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
          ),
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
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
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

// ─── Footer ─────────────────────────────────────────────────────────────────

class _CreateAccountRow extends StatelessWidget {
  const _CreateAccountRow({this.onCreateAccount});

  final VoidCallback? onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: RichText(
          text: TextSpan(
            style: AppTextStyles.label(context).copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            children: [
              const TextSpan(text: 'New to RentEase? '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
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
      ),
    );
  }
}
