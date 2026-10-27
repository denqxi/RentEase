import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/data/repositories/home_repository_impl.dart';
import '../../registration/model/match_result.dart';
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
  List<MatchResult>? _preloadedMatches;

  @override
  void initState() {
    super.initState();
    _startPreloadMatches();
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
                SuccessScreen(
                  isOwner: widget.isOwner,
                  initialMatches: _preloadedMatches,
                ),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
  }

  Future<void> _startPreloadMatches() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (!widget.isOwner) {
        if (uid != null && uid.isNotEmpty) {
          final repo = HomeRepositoryImpl();
          final listings = await repo.fetchCompatibleListings(uid);
          if (listings.isNotEmpty) {
            _preloadedMatches = listings.take(3).map(MatchResult.fromListing).toList();
            return;
          }
        }
        _preloadedMatches = <MatchResult>[];
      }
    } catch (_) {
      _preloadedMatches = <MatchResult>[];
    }
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
                        errorBuilder: (_, _, _) => const _FallbackRadar(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading(context),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Subtitle
                Text(
                  '$subtitlePrefix...',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(context),
                ),
                const SizedBox(height: 32),

                // Checklist Card (centered inside layout)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.appColors.fieldFill,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < _steps.length; i++) ...<Widget>[
                        _ChecklistRow(
                          label: _steps[i],
                          isDone: i < _completedSteps,
                          isActive: i == _completedSteps,
                        ),
                        if (i < _steps.length - 1)
                          const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
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

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
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
        SizedBox(
          width: 20,
          height: 20,
          child: isDone
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.matchHigh,
                  size: 20,
                )
              : isActive
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : Icon(
                      Icons.radio_button_unchecked,
                      color: context.appColors.indicatorInactive,
                      size: 20,
                    ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body(context).copyWith(
              color: isDone || isActive
                  ? context.appColors.textPrimary
                  : context.appColors.textSecondary,
              fontWeight:
                  isDone || isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _FallbackRadar extends StatelessWidget {
  const _FallbackRadar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        color: AppColors.accentSoft,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.radar, color: AppColors.accent, size: 64),
    );
  }
}
