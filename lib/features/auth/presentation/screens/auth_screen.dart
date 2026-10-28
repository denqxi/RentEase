import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_back_handler.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../registration/model/user_role.dart';
import '../../../registration/view/registration_flow_screen.dart';
import '../../domain/entities/auth.dart';
import '../bloc/auth_bloc.dart';
import 'email_verification_screen.dart';

/// Sign-in screen featuring a hardware-accelerated pull-up/pull-down card over
/// a hero building background with zero-rebuild transitions.
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
    with TickerProviderStateMixin, RouteAware {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();

  /// Tracks whether the card is in the expanded interaction state (>= 0.5)
  /// so [IgnorePointer] only toggles once per transition instead of every frame.
  final ValueNotifier<bool> _isExpandedNotifier = ValueNotifier<bool>(false);

  bool _rememberMe = false;
  bool _obscurePassword = true;
  int _forgotPasswordCountdown = 0;
  Timer? _forgotPasswordTimer;

  // Screen entrance animations (background image & initial card arrival).
  late final AnimationController _entranceCtrl;
  late final Animation<double> _imageFade;
  late final Animation<double> _imageScale;
  late final Animation<Offset> _initialCardSlide;

  // Card interactive expansion animation (0.0 = minimized, 1.0 = expanded).
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandCurve;

  // Pre-built render-layer animations driven by [_expandCtrl] (zero rebuilds).
  late final Animation<Offset> _bgImageSlide;
  late final Animation<double> _bgHeaderFade;
  late final Animation<Offset> _bgHeaderSlide;
  late final Animation<double> _minimizedFade;
  late final Animation<double> _expandedFade;
  late final Animation<Offset> _expandedContentSlide;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.entrance,
    );

    _imageFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.70, curve: Curves.easeOut),
    );

    _imageScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _initialCardSlide = Tween<Offset>(
      begin: const Offset(0, 0.30),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.05, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 260),
    )..addListener(_onExpandTick);

    _expandCurve = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    );

    _bgImageSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.075),
    ).animate(_expandCurve);

    _bgHeaderFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _expandCtrl,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOut),
      ),
    );

    _bgHeaderSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.18),
    ).animate(
      CurvedAnimation(
        parent: _expandCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _minimizedFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _expandCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _expandedFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _expandCtrl,
        curve: const Interval(0.18, 0.85, curve: Curves.easeOut),
      ),
    );

    _expandedContentSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _expandCtrl,
        curve: const Interval(0.15, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceCtrl.forward();
    });
  }

  void _onExpandTick() {
    final shouldBeExpanded = _expandCtrl.value >= 0.5;
    if (_isExpandedNotifier.value != shouldBeExpanded) {
      _isExpandedNotifier.value = shouldBeExpanded;
      if (!shouldBeExpanded) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      AppRouter.routeObserver.subscribe(this, modalRoute);
    }
    precacheImage(const AssetImage('assets/images/building2.png'), context);
    precacheImage(
      const ResizeImage(
        AssetImage('assets/images/signinminimized.png'),
        width: 360,
      ),
      context,
    );
  }

  @override
  void didPopNext() {
    if (mounted) _entranceCtrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    _forgotPasswordTimer?.cancel();
    AppRouter.routeObserver.unsubscribe(this);
    _expandCtrl.removeListener(_onExpandTick);
    _isExpandedNotifier.dispose();
    _entranceCtrl.dispose();
    _expandCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  AuthBloc? _getAuthBloc() {
    try {
      return context.read<AuthBloc>();
    } catch (_) {
      return null;
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
    _getAuthBloc()?.add(
          AuthSignInRequested(email: email, password: password),
        );
  }

  void _handleForgotPassword() {
    if (_forgotPasswordCountdown > 0) return;
    final email = _emailController.text.trim();
    final emailError = Validators.email(email);
    if (emailError != null) {
      _showError('Enter your email above first, then tap "Forgot password?".');
      return;
    }
    setState(() => _forgotPasswordCountdown = 40);
    _forgotPasswordTimer?.cancel();
    _forgotPasswordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_forgotPasswordCountdown > 1) {
        setState(() => _forgotPasswordCountdown--);
      } else {
        timer.cancel();
        setState(() => _forgotPasswordCountdown = 0);
      }
    });
    _getAuthBloc()?.add(AuthPasswordResetRequested(email: email));
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _expandCtrl.stop();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, double dragDistance) {
    if (dragDistance <= 0) return;
    final delta = -details.primaryDelta! / dragDistance;
    _expandCtrl.value = (_expandCtrl.value + delta).clamp(0.0, 1.0);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = -details.primaryVelocity!;
    if (velocity > 220) {
      _expandCtrl.forward();
    } else if (velocity < -220) {
      _expandCtrl.reverse();
    } else if (_expandCtrl.value > 0.5) {
      _expandCtrl.forward();
    } else {
      _expandCtrl.reverse();
    }
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;

    if (state is AuthAuthenticated) {
      widget.onSignIn?.call(state.user);
    } else if (state is AuthGoogleUserNeedsRegistration) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RegistrationFlowScreen(
            initialGoogleResult: state.googleResult,
            onComplete: (role) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                role == UserRole.landlord
                    ? AppRouter.documentUpload
                    : AppRouter.hardConstraints,
                (_) => false,
              );
            },
            onSignIn: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } else if (state is AuthEmailNotVerified) {
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
        SnackBar(
          content: Text('Password reset link sent to ${state.email}.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authBloc = _getAuthBloc();
    final scaffold = _buildScaffold(context, authBloc);

    final wrapped = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_expandCtrl.value > 0) {
          _expandCtrl.reverse();
        } else {
          await AppBackHandler.minimizeOrPop();
        }
      },
      child: scaffold,
    );

    if (authBloc != null) {
      return BlocListener<AuthBloc, AuthState>(
        bloc: authBloc,
        listener: _onAuthStateChanged,
        child: wrapped,
      );
    }

    return wrapped;
  }

  Widget _buildScaffold(BuildContext context, AuthBloc? authBloc) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = size.height;
    final bottomInset = padding.bottom;
    final topInset = padding.top;

    final collapsedHeight = 156.0 + bottomInset;
    final expandedHeight = (488.0 + bottomInset).clamp(
      450.0,
      screenHeight - topInset - 24.0,
    );
    final dragDistance = expandedHeight - collapsedHeight;

    final minimizedLayer = FadeTransition(
      opacity: _minimizedFade,
      child: RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _expandCtrl.forward(),
          child: _MinimizedCardContent(bottomInset: bottomInset),
        ),
      ),
    );

    Widget buildExpandedLayer({bool isLoading = false, bool isSuspended = false}) {
      return FadeTransition(
        opacity: _expandedFade,
        child: SlideTransition(
          position: _expandedContentSlide,
          child: RepaintBoundary(
            child: _ExpandedCardContent(
              scrollController: _scrollController,
              isKeyboardOpen: keyboardBottom > 0,
              bottomInset: bottomInset,
              emailController: _emailController,
              passwordController: _passwordController,
              rememberMe: _rememberMe,
              obscurePassword: _obscurePassword,
              isLoading: isLoading,
              isSuspended: isSuspended,
              forgotPasswordCountdown: _forgotPasswordCountdown,
              onRememberMeChanged: (v) =>
                  setState(() => _rememberMe = v ?? false),
              onTogglePassword: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onCreateAccount: widget.onCreateAccount,
              onSignIn: _handleSignIn,
              onForgotPassword: _handleForgotPassword,
              onPullDown: () => _expandCtrl.reverse(),
            ),
          ),
        ),
      );
    }

    final Widget expandedStateWrapper = authBloc == null
        ? buildExpandedLayer()
        : BlocBuilder<AuthBloc, AuthState>(
            bloc: authBloc,
            buildWhen: (p, c) =>
                (p is AuthLoading) != (c is AuthLoading) ||
                (p is AuthSuspended) != (c is AuthSuspended),
            builder: (context, authState) => buildExpandedLayer(
              isLoading: authState is AuthLoading,
              isSuspended: authState is AuthSuspended,
            ),
          );

    // Static card subtree — built ONCE and passed as `child` to AnimatedBuilder
    // so dragging/animating performs ZERO widget rebuilds or layout passes.
    final staticCard = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: (details) =>
          _onVerticalDragUpdate(details, dragDistance),
      onVerticalDragEnd: _onVerticalDragEnd,
      child: Container(
        width: double.infinity,
        height: expandedHeight,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.card),
          ),
          boxShadow: [
            BoxShadow(
              color: context.appColors.ink.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ValueListenableBuilder<bool>(
          valueListenable: _isExpandedNotifier,
          builder: (context, isExpanded, _) {
            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: collapsedHeight,
                  child: IgnorePointer(
                    ignoring: isExpanded,
                    child: minimizedLayer,
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !isExpanded,
                    child: expandedStateWrapper,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    return Scaffold(
      backgroundColor: context.appColors.surface,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Hero Background (RenderObject SlideTransition + RepaintBoundary) ─
          RepaintBoundary(
            child: ScaleTransition(
              scale: _imageScale,
              child: FadeTransition(
                opacity: _imageFade,
                child: SlideTransition(
                  position: _bgImageSlide,
                  child: const _SignInBackground(),
                ),
              ),
            ),
          ),

          // ── Background Header & Subheader (Zero-rebuild Fade/Slide) ─────
          Positioned(
            top: topInset + 68,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isExpandedNotifier,
              child: FadeTransition(
                opacity: _bgHeaderFade,
                child: SlideTransition(
                  position: _bgHeaderSlide,
                  child: RepaintBoundary(
                    child: GestureDetector(
                      onLongPress: () =>
                          Navigator.of(context).pushNamed(AppRouter.adminLogin),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                                height: 1.05,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Rent',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Ease',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Find your next home,\nmade easy.',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              builder: (context, isExpanded, headerChild) {
                return IgnorePointer(
                  ignoring: isExpanded,
                  child: headerChild,
                );
              },
            ),
          ),

          // ── Pull-up / Pull-down Bottom Card (Zero-rebuild Translation) ──
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _initialCardSlide,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _expandCurve,
                  child: staticCard,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, dragDistance * (1.0 - _expandCurve.value)),
                      child: child,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background ──────────────────────────────────────────────────────────────

class _SignInBackground extends StatelessWidget {
  const _SignInBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/building2.png',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              AppColors.primaryMid,
              context.appColors.ink,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Drag Handle Pill ────────────────────────────────────────────────────────

class _DragHandlePill extends StatelessWidget {
  const _DragHandlePill({this.showTapHint = false});

  final bool showTapHint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4.5,
            margin: const EdgeInsets.only(top: 10, bottom: 3),
            decoration: BoxDecoration(
              color: context.appColors.indicatorInactive,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          if (showTapHint)
            Text(
              'Tap',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w300,
                color: context.appColors.hint,
                letterSpacing: 0.5,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Minimized Card Content ──────────────────────────────────────────────────

class _MinimizedCardContent extends StatelessWidget {
  const _MinimizedCardContent({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Graphic illustration on the bottom right (downsampled for fast GPU rasterization)
        Positioned(
          right: -8,
          bottom: bottomInset > 0 ? bottomInset - 8 : 0,
          width: 180,
          height: 180,
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/signinminimized.png',
              cacheWidth: 360,
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        // Content: Sign In header and subheader positioned slightly higher
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            bottomInset + 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DragHandlePill(showTapHint: true),
              Expanded(
                child: Align(
                  alignment: const Alignment(-1.0, -0.45),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign In',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: context.appColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Continue your rental journey\nwith RentEase.',
                        style: AppTextStyles.body(context).copyWith(
                          color: context.appColors.textSecondary,
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Expanded Card Content ───────────────────────────────────────────────────

class _ExpandedCardContent extends StatelessWidget {
  const _ExpandedCardContent({
    required this.scrollController,
    required this.isKeyboardOpen,
    required this.bottomInset,
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.onRememberMeChanged,
    required this.onTogglePassword,
    required this.onPullDown,
    this.isLoading = false,
    this.isSuspended = false,
    this.forgotPasswordCountdown = 0,
    this.onCreateAccount,
    this.onSignIn,
    this.onForgotPassword,
  });

  final ScrollController scrollController;
  final bool isKeyboardOpen;
  final double bottomInset;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final bool isLoading;
  final bool isSuspended;
  final int forgotPasswordCountdown;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onPullDown;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onSignIn;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    // Blue theme outline only when the field is focused (user is inputting)
    final blueFocused = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        // Top drag handle bar
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPullDown,
          child: const _DragHandlePill(),
        ),

        // Form content: NeverScrollable when keyboard is closed so vertical
        // drags anywhere on the card smoothly collapse the sheet without conflict.
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            physics: isKeyboardOpen
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              14, // Symmetrical top spacing above Welcome header
              AppSpacing.lg,
              14 + bottomInset, // Symmetrical bottom spacing
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (Welcome back) - Long press opens Admin Login
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () =>
                      Navigator.of(context).pushNamed(AppRouter.adminLogin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back.',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: context.appColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to continue your rental journey.',
                        style: AppTextStyles.body(context).copyWith(
                          color: context.appColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isSuspended) ...[
                  const SizedBox(height: AppSpacing.md),
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
                      style: AppTextStyles.body(context).copyWith(
                        color: AppColors.destructive,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14), // Symmetrical bottom space under header

                // 2. Fields (neutral border when idle, blue outline when focused)
                LabelledField(
                  label: 'Email address',
                  child: AppTextField(
                    controller: emailController,
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    focusedBorderColor: blueFocused,
                  ),
                ),
                const SizedBox(height: 12),
                LabelledField(
                  label: 'Password',
                  child: AppTextField(
                    controller: passwordController,
                    hintText: 'Enter your password',
                    obscureText: obscurePassword,
                    focusedBorderColor: blueFocused,
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
                ),
                const SizedBox(height: 10),
                _RememberForgotRow(
                  rememberMe: rememberMe,
                  onChanged: onRememberMeChanged,
                  onForgotPassword: onForgotPassword,
                  forgotPasswordCountdown: forgotPasswordCountdown,
                ),

                const SizedBox(height: 16),

                // 3. Primary Button (Sign In) — App's dark primary button color
                AppPrimaryButton(
                  label: isLoading ? 'Signing in…' : 'Sign In',
                  onPressed: isLoading ? null : (onSignIn ?? () {}),
                ),

                const SizedBox(height: 14),

                // 4. Social & Create Account
                const _OrDivider(),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: _GoogleButton()),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(child: _GuestButton()),
                  ],
                ),
                const SizedBox(height: 14),
                _CreateAccountRow(onCreateAccount: onCreateAccount),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Form Elements & Rows ────────────────────────────────────────────────────

class _RememberForgotRow extends StatelessWidget {
  const _RememberForgotRow({
    required this.rememberMe,
    required this.onChanged,
    this.onForgotPassword,
    this.forgotPasswordCountdown = 0,
  });

  final bool rememberMe;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onForgotPassword;
  final int forgotPasswordCountdown;

  @override
  Widget build(BuildContext context) {
    final isCountingDown = forgotPasswordCountdown > 0;
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: rememberMe,
            onChanged: onChanged,
            activeColor: context.appColors.ink,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            side: BorderSide(color: context.appColors.hint, width: 1.5),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: () => onChanged(!rememberMe),
          child: Text(
            'Remember me',
            style: AppTextStyles.label(context).copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: isCountingDown ? null : onForgotPassword,
          child: Text(
            isCountingDown
                ? 'Forgot password? (${forgotPasswordCountdown}s)'
                : 'Forgot password?',
            style: AppTextStyles.label(context).copyWith(
              color: isCountingDown
                  ? context.appColors.hint
                  : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Divider & Social ────────────────────────────────────────────────────────

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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
    bool isLoading = false;
    try {
      final bloc = context.read<AuthBloc>();
      isLoading = bloc.state is AuthLoading;
    } catch (_) {}

    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: OutlinedButton(
        onPressed: isLoading
            ? null
            : () {
                try {
                  context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
                } catch (_) {}
              },
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
            const SizedBox(
              width: 20,
              height: 20,
              child: RepaintBoundary(
                child: CustomPaint(painter: _GoogleLogoPainter()),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
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

class _GuestButton extends StatelessWidget {
  const _GuestButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
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
              cacheWidth: 48,
              errorBuilder: (_, _, _) => Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
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

// ── Footer ──────────────────────────────────────────────────────────────────

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
                    color: Theme.of(context).colorScheme.primary,
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

// ── Google Brand Logo Painter ───────────────────────────────────────────────

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

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
