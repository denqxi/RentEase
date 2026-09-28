import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../cubit/registration_cubit.dart';

/// Shown immediately after account creation — prompts the user to verify
/// the email address they entered before continuing the flow.
class CheckEmailView extends StatefulWidget {
  const CheckEmailView({super.key});

  @override
  State<CheckEmailView> createState() => _CheckEmailViewState();
}

class _CheckEmailViewState extends State<CheckEmailView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  // Lottie scale & fade animations
  late final Animation<double> _lottieScale;
  late final Animation<double> _lottieFade;

  // Text slide & fade animations
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;

  // Button slide & fade animations
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonFade;

  // Resend email countdown timer (30s)
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

    // Lottie animation: scale-up with easeOutBack + fade
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

    // Text: slide-up + fade
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.10, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.10, 0.60, curve: Curves.easeOut),
    );

    // Action button & links: slide-up + fade
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.40),
      end: Offset.zero,
    ).animate(
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
      if (mounted) {
        _animCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    if (_resendCountdown > 0) return;

    setState(() {
      _resendCountdown = 30;
    });

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
    final email = context.watch<RegistrationCubit>().state.data.email;
    final displayEmail = email.isNotEmpty ? email : 'email@gmail.com';
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 360;
    final padding = isCompact ? AppSpacing.md : AppSpacing.lg;

    return SafeArea(
      top: false,
      bottom: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final lottieSize = constraints.maxHeight < 550 ? 150.0 : (isCompact ? 180.0 : 210.0);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, padding, padding, padding),
                  child: Column(
                    children: [
                      const Spacer(),

                      // Animated looping Lottie animation with Scale-up & Fade
                      RepaintBoundary(
                        child: ScaleTransition(
                          scale: _lottieScale,
                          child: FadeTransition(
                            opacity: _lottieFade,
                            child: SizedBox(
                              width: lottieSize,
                              height: lottieSize,
                              child: Lottie.asset(
                                'assets/images/email.json',
                                width: lottieSize,
                                height: lottieSize,
                                fit: BoxFit.contain,
                                repeat: true,
                                animate: true,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.mark_email_unread_rounded,
                                    color: AppColors.accent,
                                    size: lottieSize * 0.45,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isCompact ? AppSpacing.lg : AppSpacing.xl),

                      // Animated Headers and Subtitles (Slide Up + Fade)
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
                                SizedBox(height: isCompact ? AppSpacing.sm : AppSpacing.md),
                                Text.rich(
                                  TextSpan(
                                    text: 'We sent a verification link to ',
                                    style: AppTextStyles.body(context).copyWith(
                                      color: context.appColors.textSecondary,
                                      height: 1.5,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: displayEmail,
                                        style: AppTextStyles.body(context).copyWith(
                                          color: context.appColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          height: 1.5,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: '.\nPlease tap the link inside the email to verify.',
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),
                      SizedBox(height: isCompact ? AppSpacing.md : AppSpacing.lg),

                      // Animated Button and Resend Link (Slide Up + Fade)
                      RepaintBoundary(
                        child: SlideTransition(
                          position: _buttonSlide,
                          child: FadeTransition(
                            opacity: _buttonFade,
                            child: Column(
                              children: [
                                AppPrimaryButton(
                                  label: 'Open email app',
                                  onPressed: () => context.read<RegistrationCubit>().next(),
                                ),
                                SizedBox(height: isCompact ? AppSpacing.sm : AppSpacing.md),
                                GestureDetector(
                                  onTap: _resendCountdown == 0 ? _startResendTimer : null,
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
                                const SizedBox(height: AppSpacing.xs),
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
          );
        },
      ),
    );
  }
}
