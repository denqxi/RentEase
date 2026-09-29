import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';

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

class _MatchingTransitionScreenState extends State<MatchingTransitionScreen> {
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

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted) return;
      if (_completedSteps < _steps.length) {
        setState(() => _completedSteps++);
      } else {
        timer.cancel();
        Navigator.of(context).pushNamedAndRemoveUntil(
          widget.isOwner ? AppRouter.landlordHome : AppRouter.tenantHome,
          (_) => false,
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
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.accent,
                        backgroundColor: AppColors.accentSoft,
                      ),
                    ),
                    Icon(
                      widget.isOwner
                          ? Icons.home_work_outlined
                          : Icons.favorite_border,
                      color: AppColors.accent,
                      size: 30,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Text(
                widget.isOwner
                    ? 'Setting up your dashboard'
                    : 'Finding your matches',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: context.appColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                widget.isOwner
                    ? 'We are matching your property against tenant profiles.'
                    : 'We are matching your profile against available properties.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  color: context.appColors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              for (int i = 0; i < _steps.length; i++) ...[
                _StepRow(
                  label: _steps[i],
                  isDone: i < _completedSteps,
                  isActive: i == _completedSteps,
                ),
                if (i < _steps.length - 1) SizedBox(height: AppSpacing.md),
              ],
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
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: isDone
              ? AppColors.matchHigh
              : (isActive
                  ? AppColors.accent
                  : context.appColors.indicatorInactive),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            fontWeight: isDone || isActive ? FontWeight.w600 : FontWeight.w400,
            color: isDone || isActive
                ? context.appColors.textPrimary
                : context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
