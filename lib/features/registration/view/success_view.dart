import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../home/data/repositories/home_repository_impl.dart';
import '../model/match_result.dart';
import '../widgets/match_card.dart';

/// "You're all set!" — confirmation shown once onboarding completes.
///
/// Plays the Lottie checkmark animation at the top, then reveals all components
/// (title, subtitle, match cards, and action buttons) with an animated slide-up
/// sequence driven by an [AnimationController] with staggered [Interval] curves.
class SuccessView extends StatefulWidget {
  const SuccessView({
    required this.onExplore,
    this.isOwner = false,
    this.onBackToStart,
    this.initialMatches,
    super.key,
  });

  /// Tapped on "Explore RentEase".
  final VoidCallback onExplore;

  /// Whether to show landlord copy/matches instead of tenant ones.
  final bool isOwner;

  /// Optional "Back to start" action (only shown inside the registration
  /// flow, where restarting is meaningful).
  final VoidCallback? onBackToStart;

  /// Optional preloaded real matched properties.
  final List<MatchResult>? initialMatches;

  @override
  State<SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<SuccessView>
    with TickerProviderStateMixin {
  static const Duration _componentsDuration = Duration(milliseconds: 550);

  /// Interval windows for each staggered component:
  /// 0: Title & Subtitle
  /// 1: Match Card 1 / Empty State
  /// 2: Match Card 2
  /// 3: Match Card 3
  /// 4: Explore Action Button
  static const List<Interval> _intervals = <Interval>[
    Interval(0.05, 0.45, curve: Curves.easeOutCubic),
    Interval(0.20, 0.60, curve: Curves.easeOutCubic),
    Interval(0.35, 0.75, curve: Curves.easeOutCubic),
    Interval(0.50, 0.90, curve: Curves.easeOutCubic),
    Interval(0.60, 1.00, curve: Curves.easeOutCubic),
  ];

  late final AnimationController _lottieAnimCtrl;
  late final Animation<double> _lottieScale;
  late final Animation<double> _lottieFade;

  late final AnimationController _componentsCtrl;
  late final List<Animation<double>> _componentAnimations;

  late List<MatchResult> _matches;

  @override
  void initState() {
    super.initState();

    if (widget.initialMatches != null) {
      _matches = widget.initialMatches!;
    } else {
      _matches = <MatchResult>[];
      _fetchRealMatches();
    }

    // 1. Lottie checkmark graphic animation controller
    _lottieAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _lottieScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _lottieAnimCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _lottieFade = CurvedAnimation(
      parent: _lottieAnimCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    // 2. Domino slide-up animation controller for all screen components
    _componentsCtrl = AnimationController(
      vsync: this,
      duration: _componentsDuration,
    );
    _componentAnimations = _intervals
        .map((interval) => CurvedAnimation(
              parent: _componentsCtrl,
              curve: interval,
            ))
        .toList(growable: false);

    // Start playing graphic and cascade component slide-up
    _lottieAnimCtrl.forward();
    _componentsCtrl.forward();
  }

  Future<void> _fetchRealMatches() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (!widget.isOwner) {
        if (uid != null && uid.isNotEmpty) {
          final repo = HomeRepositoryImpl();
          final listings = await repo.fetchCompatibleListings(uid);
          if (mounted) {
            setState(() {
              _matches = listings.take(3).map(MatchResult.fromListing).toList();
            });
            return;
          }
        }
        if (mounted) {
          setState(() {
            _matches = <MatchResult>[];
          });
        }
      }
    } catch (e) {
      debugPrint('SuccessView: error fetching real matches: $e');
    }
  }

  @override
  void dispose() {
    _lottieAnimCtrl.dispose();
    _componentsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches.take(3).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: AppSpacing.xl),

                  // Top Lottie Graphic Animation
                  Semantics(
                    label: 'Success Checkmark',
                    image: true,
                    child: RepaintBoundary(
                      child: ScaleTransition(
                        scale: _lottieScale,
                        child: FadeTransition(
                          opacity: _lottieFade,
                          child: SizedBox(
                            width: 110,
                            height: 110,
                            child: Lottie.asset(
                              'assets/images/check_success.json',
                              width: 110,
                              height: 110,
                              repeat: false,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const _SuccessBadge(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Component 1: Slide-up Header Text (Title & Subtitle)
                  _SlideUpComponent(
                    animation: _componentAnimations[0],
                    child: _HeaderTexts(
                      isOwner: widget.isOwner,
                      hasMatches: matches.isNotEmpty,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Components 2, 3, 4: Slide-up Match Cards OR Empty State
                  if (matches.isEmpty)
                    _SlideUpComponent(
                      animation: _componentAnimations[1],
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: context.appColors.fieldFill,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: context.appColors.fieldBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_off_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              widget.isOwner
                                  ? 'No matching tenants yet'
                                  : 'No exact matches found yet',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: context.appColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.isOwner
                                  ? 'Your listing is active. You will receive notifications when matching tenants view or inquire.'
                                  : 'We didn\'t find properties matching all your criteria right now. You can explore all available properties on the home screen or adjust your preferences anytime.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: context.appColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    for (int i = 0; i < matches.length; i++) ...<Widget>[
                      _SlideUpComponent(
                        animation: i + 1 < _componentAnimations.length
                            ? _componentAnimations[1 + i]
                            : _componentAnimations.last,
                        child: MatchCard(match: matches[i]),
                      ),
                      if (i < matches.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Component 5: Slide-up Action Button
          _SlideUpComponent(
            animation: _componentAnimations[4],
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppPrimaryButton(
                    label: 'Explore RentEase',
                    onPressed: widget.onExplore,
                  ),
                  if (widget.onBackToStart != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: widget.onBackToStart,
                      child: Text(
                        'Back to start',
                        style: AppTextStyles.link(context).copyWith(
                          color: context.appColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header title and subtitle text.
class _HeaderTexts extends StatelessWidget {
  const _HeaderTexts({required this.isOwner, this.hasMatches = true});

  final bool isOwner;
  final bool hasMatches;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          "You're all set!",
          textAlign: TextAlign.center,
          style: AppTextStyles.heading(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isOwner
              ? (hasMatches
                  ? 'Your listing is live. We found tenants that fit your requirements.'
                  : 'Your listing is live! We will notify you once matching tenants arrive.')
              : (hasMatches
                  ? 'Your tenant profile is ready. Here are homes matched to your preferences.'
                  : 'Your tenant profile is ready! There are no exact property matches yet, but you can explore all available properties anytime.'),
          textAlign: TextAlign.center,
          style: AppTextStyles.body(context),
        ),
      ],
    );
  }
}

/// Fades and slides [child] up smoothly from an offset as [animation] runs 0 → 1.
class _SlideUpComponent extends StatelessWidget {
  const _SlideUpComponent({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// Static fallback used if the Lottie asset fails to load.
class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.accentSoft,
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: AppColors.onInk, size: 32),
      ),
    );
  }
}
