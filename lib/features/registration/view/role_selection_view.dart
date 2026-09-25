import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../cubit/registration_cubit.dart';
import '../model/user_role.dart';
import '../widgets/role_option_card.dart';
import '../widgets/step_header.dart';

/// "Join RentEase" — choose a role before starting the form.
///
/// Fully animated with 8-second staggered slide-up and fade transitions.
class RoleSelectionView extends StatefulWidget {
  const RoleSelectionView({required this.onSignIn, super.key});

  /// Tapped on the "Sign in" link for users who already have an account.
  final VoidCallback onSignIn;

  @override
  State<RoleSelectionView> createState() => _RoleSelectionViewState();
}

class _RoleSelectionViewState extends State<RoleSelectionView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  // Staggered scale-up and fade animations (8s)
  late final Animation<double> _headerScale;
  late final Animation<double> _headerFade;

  late final Animation<double> _optionsScale;
  late final Animation<double> _optionsFade;

  late final Animation<double> _buttonScale;
  late final Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();
    // 8-second smooth animation controller
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

    // Header & Subheader: scale-up + fade (Interval: 0.0 -> 0.70)
    _headerScale = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutBack),
      ),
    );
    _headerFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.50, curve: Curves.easeOut),
    );

    // Options cards: scale-up like back button + fade (Interval: 0.12 -> 0.80)
    _optionsScale = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.12, 0.80, curve: Curves.easeOutBack),
      ),
    );
    _optionsFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.12, 0.65, curve: Curves.easeOut),
    );

    // Buttons & Footer: scale-up + fade (Interval: 0.25 -> 0.90)
    _buttonScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.25, 0.90, curve: Curves.easeOutBack),
      ),
    );
    _buttonFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();
    final state = context.watch<RegistrationCubit>().state;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Header & Subheader (Scale up + fade) ────────────────────────
          RepaintBoundary(
            child: ScaleTransition(
              scale: _headerScale,
              alignment: Alignment.centerLeft,
              child: FadeTransition(
                opacity: _headerFade,
                child: StepHeader(
                  titleSpans: <InlineSpan>[
                    const TextSpan(text: 'Join '),
                    const TextSpan(
                      text: 'RentEase',
                      style: TextStyle(
                        color: Color(0xFF1ABCCE), // Light blue highlight
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  subtitle:
                      'Select how you want to use RentEase to personalize your experience.',
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Role Options (Scale up like back button + fade) ─────────────
          Expanded(
            child: RepaintBoundary(
              child: ScaleTransition(
                scale: _optionsScale,
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: _optionsFade,
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        for (final role in UserRole.values) ...<Widget>[
                          RoleOptionCard(
                            role: role,
                            selected: state.data.role == role,
                            onTap: () => cubit.selectRole(role),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Footer & Continue Button (Scale up + fade) ──────────────────
          RepaintBoundary(
            child: ScaleTransition(
              scale: _buttonScale,
              child: FadeTransition(
                opacity: _buttonFade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppPrimaryButton(
                      label: 'Continue',
                      onPressed: state.canContinueFromRole
                          ? () {
                              if (state.data.role == UserRole.guest) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRouter.tenantHome,
                                  (_) => false,
                                  arguments: UserRole.guest,
                                );
                                return;
                              }
                              cubit.next();
                            }
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: GestureDetector(
                        onTap: widget.onSignIn,
                        child: Text.rich(
                          TextSpan(
                            style: AppTextStyles.link(context),
                            children: <InlineSpan>[
                              const TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Sign in',
                                style: AppTextStyles.link(context).copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}
