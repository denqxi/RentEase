import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../registration/view/success_screen.dart';

/// Shown once between the final onboarding step and the main app, for both
/// roles. Narratively this is when Cloud Functions run the bilateral filter
/// and TOPSIS ranking server-side; the prototype simulates the wait, then
/// lands the user on their home shell.
class MatchingTransitionScreen extends StatefulWidget {
  const MatchingTransitionScreen({this.isOwner = false, super.key});

  final bool isOwner;

  @override
  State<MatchingTransitionScreen> createState() =>
      _MatchingTransitionScreenState();
}

class _MatchingTransitionScreenState extends State<MatchingTransitionScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _tenantSteps = <String>[
    'Applying your hard constraints',
    'Checking bilateral compatibility',
    'Ranking your matches with TOPSIS',
  ];

  static const List<String> _ownerSteps = <String>[
    'Publishing your property',
    'Screening compatible tenants',
    'Ranking tenants by your criteria',
  ];

  List<String> get _steps => widget.isOwner ? _ownerSteps : _tenantSteps;

  int _completedSteps = 0;
  Timer? _timer;

  late final AnimationController _animCtrl;
  late final Animation<double> _lottieScale;
  late final Animation<double> _lottieFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _stepsSlide;
  late final Animation<double> _stepsFade;
  late final Animation<Offset> _footerSlide;
  late final Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();

    // ── Entry Animations ───────────────────────────────────────────────────
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _lottieScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutBack),
      ),
    );
    _lottieFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.50, curve: Curves.easeOut),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.20, 0.80, curve: Curves.easeOutCubic),
      ),
    );
    _headerFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.20, 0.70, curve: Curves.easeOut),
    );

    _stepsSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.35, 0.90, curve: Curves.easeOutCubic),
      ),
    );
    _stepsFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.35, 0.80, curve: Curves.easeOut),
    );

    _footerSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _footerFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.45, 0.90, curve: Curves.easeOut),
    );

    _animCtrl.forward();

    // ── Step Completion Progression ────────────────────────────────────────
    _timer = Timer.periodic(const Duration(milliseconds: 950), (timer) {
      if (!mounted) return;
      if (_completedSteps < _steps.length) {
        setState(() => _completedSteps++);
      } else {
        timer.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => SuccessScreen(isOwner: widget.isOwner),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // ── Lottie Animation (Scale Up Entry & ~400x400 Display) ───────
              RepaintBoundary(
                child: ScaleTransition(
                  scale: _lottieScale,
                  child: FadeTransition(
                    opacity: _lottieFade,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 400,
                        maxHeight: 260,
                      ),
                      child: Lottie.asset(
                        'assets/images/match_transition.json',
                        width: 380,
                        height: 260,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              // ── Header & Subheader (Shifted significantly closer to graphic)
              Transform.translate(
                offset: const Offset(0, -32),
                child: RepaintBoundary(
                  child: SlideTransition(
                    position: _headerSlide,
                    child: FadeTransition(
                      opacity: _headerFade,
                      child: Column(
                        children: [
                          Text(
                            widget.isOwner
                                ? 'Setting up your dashboard'
                                : 'Finding Your Best Matches',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: context.appColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isOwner
                                ? 'We are matching your property against tenant profiles.'
                                : 'Applying your preferences to find the best fit.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 15,
                              height: 1.35,
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // ── Centered Steps Container (Slide Up Entry) ─────────────────
              RepaintBoundary(
                child: SlideTransition(
                  position: _stepsSlide,
                  child: FadeTransition(
                    opacity: _stepsFade,
                    child: Center(
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < _steps.length; i++) ...[
                              _StepRow(
                                label: _steps[i],
                                isDone: i < _completedSteps,
                                isActive: i == _completedSteps,
                              ),
                              if (i < _steps.length - 1)
                                const SizedBox(height: AppSpacing.md),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // ── Bottom Processing Indicator with Waving Dots ──────────────
              RepaintBoundary(
                child: SlideTransition(
                  position: _footerSlide,
                  child: FadeTransition(
                    opacity: _footerFade,
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 48.0),
                      child: _ProcessingWaveText(),
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

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.isDone,
    required this.isActive,
  });

  final String label;
  final bool isDone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
          child: isDone
              ? const Icon(
                  Icons.check_circle_rounded,
                  key: ValueKey('done'),
                  size: 20,
                  color: AppColors.matchHigh,
                )
              : isActive
                  ? SizedBox(
                      key: const ValueKey('active_spinner'),
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.accent,
                        backgroundColor: AppColors.accentSoft,
                      ),
                    )
                  : Container(
                      key: const ValueKey('inactive_circle'),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.appColors.indicatorInactive,
                          width: 1.8,
                        ),
                      ),
                    ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 15,
            fontWeight:
                isDone || isActive ? FontWeight.w600 : FontWeight.w400,
            color: isDone || isActive
                ? context.appColors.textPrimary
                : context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Continuous subtle wave animation on the three dots: "Processing . . ."
class _ProcessingWaveText extends StatefulWidget {
  const _ProcessingWaveText();

  @override
  State<_ProcessingWaveText> createState() => _ProcessingWaveTextState();
}

class _ProcessingWaveTextState extends State<_ProcessingWaveText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: context.appColors.textSecondary,
      letterSpacing: 0.4,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('Processing', style: style),
        const SizedBox(width: 3),
        for (int i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: _waveCtrl,
            builder: (context, child) {
              // Staggered sine wave for each dot (lifts up gently then rests)
              final sinValue =
                  math.sin((_waveCtrl.value * 2 * math.pi) - (i * 0.7));
              final double offsetY = sinValue > 0 ? -sinValue * 4.0 : 0.0;

              return Transform.translate(
                offset: Offset(0, offsetY),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Text(
                    '.',
                    style: style.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
