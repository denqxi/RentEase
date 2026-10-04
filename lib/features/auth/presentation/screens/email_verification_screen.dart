import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../features/registration/widgets/registration_app_bar.dart';
import '../bloc/auth_bloc.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({this.isOwner = false, super.key});

  final bool isOwner;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  static const _resumeCheckThrottle = Duration(seconds: 5);
  DateTime? _lastCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final bloc = context.read<AuthBloc>();
    if (bloc.state is! AuthEmailNotVerified) return;
    final now = DateTime.now();
    final last = _lastCheck;
    if (last != null && now.difference(last) < _resumeCheckThrottle) return;
    _lastCheck = now;
    bloc.add(const AuthEmailVerificationCheckRequested());
  }

  Future<void> _leave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Use a different account?'),
        content: const Text(
          'You will be signed out and returned to the sign-in screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<AuthBloc>().add(const AuthSignOutRequested());
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.signIn,
      (_) => false,
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.destructive : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            widget.isOwner ? AppRouter.documentUpload : AppRouter.hardConstraints,
            (_) => false,
          );
        } else if (state is AuthVerificationEmailResent) {
          _showMessage('Verification email re-sent.');
        } else if (state is AuthOperationFailure) {
          _showMessage(state.message, isError: true);
        }
      },
      child: _EmailVerificationBody(
        email: switch (context.read<AuthBloc>().state) {
          AuthEmailNotVerified(:final user) => user.email,
          AuthAuthenticated(:final user) => user.email,
          _ => '',
        },
        onResend: () {
          context
              .read<AuthBloc>()
              .add(const AuthEmailVerificationResendRequested());
        },
        onBack: _leave,
        onContinue: () => context
            .read<AuthBloc>()
            .add(const AuthEmailVerificationCheckRequested()),
      ),
      ),
    );
  }
}

class _EmailVerificationBody extends StatefulWidget {
  const _EmailVerificationBody({
    required this.email,
    required this.onResend,
    required this.onContinue,
    required this.onBack,
  });

  final VoidCallback onBack;
  final String email;
  final VoidCallback onResend;
  final VoidCallback onContinue;

  @override
  State<_EmailVerificationBody> createState() => _EmailVerificationBodyState();
}

class _EmailVerificationBodyState extends State<_EmailVerificationBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _lottieScale;
  late final Animation<double> _lottieFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonFade;

  // Resend countdown (30s) — presentational throttle only.
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );
    _lottieScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutBack),
      ),
    );
    _lottieFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.50, curve: Curves.easeOut),
    );
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.10, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.10, 0.60, curve: Curves.easeOut),
    );
    _buttonSlide =
        Tween<Offset>(begin: const Offset(0, 0.40), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.20, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _buttonFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.20, 0.70, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _resend() {
    if (_resendCountdown > 0) return;
    widget.onResend();
    setState(() => _resendCountdown = 30);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 1) {
          _resendCountdown--;
        } else {
          _resendCountdown = 0;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegistrationAppBar(
                onBack: widget.onBack,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RepaintBoundary(
                            child: ScaleTransition(
                              scale: _lottieScale,
                              child: FadeTransition(
                                opacity: _lottieFade,
                                child: SizedBox(
                                  width: 210,
                                  height: 210,
                                  child: Lottie.asset(
                                    'assets/images/email.json',
                                    fit: BoxFit.contain,
                                    repeat: true,
                                    errorBuilder: (context, error, stack) =>
                                        const Icon(
                                      Icons.mark_email_unread_rounded,
                                      color: AppColors.accent,
                                      size: 96,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          RepaintBoundary(
                            child: SlideTransition(
                              position: _textSlide,
                              child: FadeTransition(
                                opacity: _textFade,
                                child: Column(
                                  children: [
                                    Text(
                                      'Verify your email',
                                      style: AppTextStyles.heading(context),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text.rich(
                                      TextSpan(
                                        text: email.isNotEmpty
                                            ? 'We sent a verification link to '
                                            : 'We sent a verification link to your email address',
                                        style: AppTextStyles.body(context)
                                            .copyWith(
                                          color:
                                              context.appColors.textSecondary,
                                          height: 1.5,
                                        ),
                                        children: [
                                          if (email.isNotEmpty)
                                            TextSpan(
                                              text: email,
                                              style:
                                                  AppTextStyles.body(context)
                                                      .copyWith(
                                                color: context
                                                    .appColors.textPrimary,
                                                fontWeight: FontWeight.w700,
                                                height: 1.5,
                                              ),
                                            ),
                                          const TextSpan(
                                            text:
                                                '.\nPlease tap the link inside the email to verify.',
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      "Check your spam folder if you don't see it.",
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.caption(context)
                                          .copyWith(
                                        color: context.appColors.hint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              RepaintBoundary(
                child: SlideTransition(
                  position: _buttonSlide,
                  child: FadeTransition(
                    opacity: _buttonFade,
                    child: Column(
                      children: [
                        AppPrimaryButton(
                          label: "I've verified my email",
                          onPressed: widget.onContinue,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GestureDetector(
                          onTap: _resendCountdown == 0 ? _resend : null,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                              horizontal: AppSpacing.sm,
                            ),
                            child: Text(
                              _resendCountdown > 0
                                  ? 'Resend Email [${_resendCountdown}s]'
                                  : 'Resend Email',
                              style: _resendCountdown > 0
                                  ? AppTextStyles.body(context).copyWith(
                                      color: context.appColors.hint,
                                      fontWeight: FontWeight.w600,
                                    )
                                  : AppTextStyles.link(context).copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onBack,
                          child: Text(
                            'Use a different account',
                            style: AppTextStyles.link(context),
                          ),
                        ),
                      ],
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
