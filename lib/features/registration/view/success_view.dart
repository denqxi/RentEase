import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../cubit/registration_cubit.dart';
import '../model/match_result.dart';
import '../model/user_role.dart';
import '../widgets/match_card.dart';

/// "You're all set!" — confirmation shown once registration completes.
///
/// - For Tenant: Displays 100x100 looping success check, header, top 3 property matches, and action buttons.
/// - For Owner: Displays 200x200 looping success check, header, updated subheader, and action buttons (no property list).
class SuccessView extends StatefulWidget {
  const SuccessView({required this.onExplore, super.key});

  /// Tapped on "Explore RentEase".
  final VoidCallback onExplore;

  @override
  State<SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<SuccessView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  late final Animation<Offset> _headerSlide;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _card1Slide;
  late final Animation<double> _card1Fade;
  late final Animation<Offset> _card2Slide;
  late final Animation<double> _card2Fade;
  late final Animation<Offset> _card3Slide;
  late final Animation<double> _card3Fade;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.40),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    _headerFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    _card1Slide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.18, 0.60, curve: Curves.easeOutCubic),
      ),
    );
    _card1Fade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.18, 0.50, curve: Curves.easeOut),
    );

    _card2Slide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _card2Fade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
    );

    _card3Slide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.50, 0.90, curve: Curves.easeOutCubic),
      ),
    );
    _card3Fade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.50, 0.80, curve: Curves.easeOut),
    );

    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.65, 1.00, curve: Curves.easeOutCubic),
      ),
    );
    _buttonFade = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.65, 0.95, curve: Curves.easeOut),
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
    final role = context.watch<RegistrationCubit>().state.data.role;
    final isLandlord = role == UserRole.landlord;

    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 720 || mediaQuery.size.width < 360;
    final horizontalPadding = isCompact ? AppSpacing.md : AppSpacing.lg;
    final cardSpacing = isCompact ? 10.0 : 13.0;

    final double lottieSize = isLandlord
        ? (isCompact ? 170.0 : 200.0)
        : (isCompact ? 88.0 : 100.0);

    return SafeArea(
      top: false,
      bottom: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: AppSpacing.md,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - (AppSpacing.md * 2),
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: <Widget>[
                    if (isLandlord) const Spacer(),

                    // ── Header & Looping Check Lottie ─────────────────────────
                    RepaintBoundary(
                      child: SlideTransition(
                        position: _headerSlide,
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: Column(
                            children: [
                              SizedBox(
                                width: lottieSize,
                                height: lottieSize,
                                child: Lottie.asset(
                                  'assets/images/check_success.json',
                                  repeat: true,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              if (isLandlord) const SizedBox(height: AppSpacing.sm),
                              Text(
                                "You're all set!",
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: isCompact ? 22 : 25,
                                  fontWeight: FontWeight.w800,
                                  color: context.appColors.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                child: Text(
                                  isLandlord
                                      ? 'You can now add your listings. We found tenants that fit your requirements,'
                                      : 'Your tenant profile is ready. Here are homes matched to your preferences.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: isCompact ? 13.0 : 14.0,
                                    height: 1.35,
                                    color: context.appColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Top 3 Matches (Tenant Flow Only) ──────────────────────
                    if (!isLandlord) ...[
                      SizedBox(height: isCompact ? 12 : 16),
                      RepaintBoundary(
                        child: SlideTransition(
                          position: _card1Slide,
                          child: FadeTransition(
                            opacity: _card1Fade,
                            child: MatchCard(
                              match: MatchResult.tenantTopMatches[0],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: cardSpacing),
                      RepaintBoundary(
                        child: SlideTransition(
                          position: _card2Slide,
                          child: FadeTransition(
                            opacity: _card2Fade,
                            child: MatchCard(
                              match: MatchResult.tenantTopMatches[1],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: cardSpacing),
                      RepaintBoundary(
                        child: SlideTransition(
                          position: _card3Slide,
                          child: FadeTransition(
                            opacity: _card3Fade,
                            child: MatchCard(
                              match: MatchResult.tenantTopMatches[2],
                            ),
                          ),
                        ),
                      ),
                    ],

                    // ── Spacer pushes action buttons to bottom ────────────────
                    const Spacer(),
                    SizedBox(height: isCompact ? 18 : 24),

                    // ── Action Buttons (Bottom Anchored & Slide Up) ───────────
                    RepaintBoundary(
                      child: SlideTransition(
                        position: _buttonSlide,
                        child: FadeTransition(
                          opacity: _buttonFade,
                          child: Column(
                            children: [
                              AppPrimaryButton(
                                label: 'Explore RentEase',
                                onPressed: widget.onExplore,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              TextButton(
                                onPressed: cubit.restart,
                                child: Text(
                                  'Back to start',
                                  style: AppTextStyles.link(context).copyWith(
                                    color: context.appColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
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
        },
      ),
    );
  }
}
