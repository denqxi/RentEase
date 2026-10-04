import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../registration/view/success_screen.dart';

/// Shown once between the final onboarding step and the success screen, for
/// both roles. Simulates server-side matching and bilateral constraints,
/// then transitions to [SuccessScreen].
class MatchingTransitionScreen extends StatefulWidget {
  const MatchingTransitionScreen({this.isOwner = false, super.key});

  final bool isOwner;

  @override
  State<MatchingTransitionScreen> createState() =>
      _MatchingTransitionScreenState();
}

class _MatchingTransitionScreenState extends State<MatchingTransitionScreen> {
  static const Duration _stepInterval = Duration(milliseconds: 900);

  static const List<String> _tenantSteps = <String>[
    'Checking your must-haves',
    'Matching house rules & lifestyle',
    'Sorting the top places for you...',
  ];

  static const List<String> _ownerSteps = <String>[
    'Checking property requirements',
    'Matching house rules & tenant criteria',
    'Sorting the top tenants for you...',
  ];

  List<String> get _steps => widget.isOwner ? _ownerSteps : _tenantSteps;

  int _completedSteps = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_stepInterval, (timer) {
      if (!mounted) return;
      if (_completedSteps < _steps.length) {
        setState(() => _completedSteps++);
      } else {
        timer.cancel();
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (_, _, _) =>
                SuccessScreen(isOwner: widget.isOwner),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Finding your best fit';

    final subtitlePrefix = widget.isOwner
        ? 'Matching tenants to your property'
        : 'Matching rooms to your preferences';

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Lottie Radar Graphic (contained height so visual gap to header matches subheader-to-card)
                Semantics(
                  label: title,
                  image: true,
                  child: RepaintBoundary(
                    child: SizedBox(
                      width: 190,
                      height: 150,
                      child: Lottie.asset(
                        'assets/images/match_transition.json',
                        width: 190,
                        height: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            _RadarFallback(isOwner: widget.isOwner),
                      ),
                    ),
                  ),
                ),
                // Same visual distance to header as subheader to card (~26px)
                const SizedBox(height: 10),

                // Header
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Subheader with integrated, spaced gray bouncing dots: " . . ."
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      subtitlePrefix,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3.5),
                      child: _BouncingDots(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Distance to card (~26px)
                const SizedBox(height: 26),

                // Card with rounded edge outline and 3 check rows
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.appColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: context.appColors.fieldBorder,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int i = 0; i < _steps.length; i++) ...<Widget>[
                        _StepRow(
                          label: _steps[i],
                          isDone: i < _completedSteps,
                          isActive: i == _completedSteps,
                        ),
                        if (i < _steps.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: context.appColors.fieldBorder
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                // Increased spacing between card and footer
                const SizedBox(height: 38),

                // Footer text
                Text(
                  'This will take a moment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three dots bouncing in a sine wave, matching the subheader typography with spaces between dots.
class _BouncingDots extends StatefulWidget {
  const _BouncingDots({required this.color});

  final Color color;

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  static const int _dotCount = 3;
  static const double _dotSize = 3.5;
  static const double _amplitude = 3.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: _dotSize + _amplitude,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (int i = 0; i < _dotCount; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: Transform.translate(
                      offset: Offset(0, -_amplitude * _waveAt(i)),
                      child: Container(
                        width: _dotSize,
                        height: _dotSize,
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Positive half of a sine wave, delayed by 0.2 of a cycle per dot.
  double _waveAt(int index) {
    final t = (_controller.value - index * 0.2) % 1.0;
    return math.max(0, math.sin(t * 2 * math.pi));
  }
}

/// Circular fallback shown if the Lottie radar fails to load.
class _RadarFallback extends StatelessWidget {
  const _RadarFallback({required this.isOwner});

  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox(
              width: 96,
              height: 96,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.accent,
                backgroundColor: AppColors.accentSoft,
              ),
            ),
            Icon(
              isOwner ? Icons.home_work_outlined : Icons.favorite_border,
              color: AppColors.accent,
              size: 36,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single step row with a custom check badge / arc spinner and label.
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
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: _buildStatusIcon(context),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 15,
              fontWeight:
                  isDone || isActive ? FontWeight.w600 : FontWeight.w500,
              color: isDone || isActive
                  ? context.appColors.textPrimary
                  : context.appColors.textSecondary.withValues(alpha: 0.65),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    if (isDone) {
      // Completed: circular teal badge with white checkmark
      return Container(
        key: const ValueKey<String>('done'),
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 14,
        ),
      );
    } else if (isActive) {
      // Active: circular arc progress spinner in brand teal
      return const SizedBox(
        key: ValueKey<String>('active'),
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.3,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
        ),
      );
    } else {
      // Pending: subtle outlined circle
      return Container(
        key: const ValueKey<String>('pending'),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: context.appColors.fieldBorder,
            width: 1.8,
          ),
        ),
      );
    }
  }
}
