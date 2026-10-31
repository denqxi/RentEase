import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/guest_access_sheet.dart';
import '../../activity/cubit/activity_cubit.dart';
import '../../activity/view/activity_screen.dart';
import '../../app_update/cubit/app_update_cubit.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../shell/cubit/shell_cubit.dart';
import '../../profile/view/edit_constraints_screen.dart';
import '../../registration/model/user_role.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_content_skeleton.dart';
import '../widgets/home_header.dart';
import '../widgets/nearby_section.dart';
import '../widgets/other_listings_section.dart';
import '../widgets/recommended_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _otherListingsKey = GlobalKey();

  void _scrollToOtherListings() {
    final targetContext = _otherListingsKey.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ProfileState? profileState;
    try {
      profileState = context.watch<ProfileCubit>().state;
    } catch (_) {
      // In isolated tests/previews without ProfileCubit
    }

    final isGuest = profileState?.userRole == UserRole.guest;
    final fullName = profileState?.fullName ?? '';
    final firstName = firstNameOf(fullName);
    final photoUrl = profileState?.photoUrl;

    int unreadNotifications = 0;
    try {
      unreadNotifications = context.select<ActivityCubit, int>(
        (c) => c.state.unreadCount,
      );
    } catch (_) {
      // In isolated tests/previews without ActivityCubit
    }
    final hasAppUpdate = context.watch<AppUpdateCubit?>()?.state.hasUpdate ?? false;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: Stack(
        children: <Widget>[
          // Subtle top-right gradient — spread softly across the header & upper content
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 195,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.05,
                    colors: <Color>[
                      AppColors.skyFill.withValues(alpha: 0.70),
                      AppColors.skyFill.withValues(alpha: 0.35),
                      AppColors.skyFill.withValues(alpha: 0.0),
                    ],
                    stops: const <double>[0.0, 0.45, 0.88],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                // Fixed top bar — stays stationary on pull down & scroll
                HomeHeader(
                  userName: isGuest
                      ? 'Guest'
                      : (firstName.isEmpty ? 'Tenant' : firstName),
                  photoUrl: photoUrl,
                  isGuest: isGuest,
                  hasUnreadNotifications: !isGuest && (unreadNotifications > 0 || hasAppUpdate),
                  onNotificationTap: () async {
                    if (isGuest) {
                      GuestAccessSheet.show(context);
                    } else {
                      final shellCubit = context.read<ShellCubit?>();
                      final activityCubit = context.read<ActivityCubit?>();
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute<dynamic>(
                          builder: (_) {
                            final screen = ActivityScreen(
                              onOpenProfile: () => shellCubit?.selectTab(ShellTab.profile),
                            );
                            if (activityCubit != null) {
                              return BlocProvider<ActivityCubit>.value(
                                value: activityCubit,
                                child: screen,
                              );
                            }
                            return screen;
                          },
                        ),
                      );
                      if (result == 'open_profile' && context.mounted) {
                        shellCubit?.selectTab(ShellTab.profile);
                      }
                    }
                  },
                ),
                // Invisible separation between the top bar and the section below
                const SizedBox(height: AppSpacing.xs),
            // Scrollable section with pull-to-refresh
            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                buildWhen: (prev, curr) =>
                    prev.isLoading != curr.isLoading ||
                    prev.errorMessage != curr.errorMessage ||
                    prev.listings.isEmpty != curr.listings.isEmpty,
                builder: (context, state) {
                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    edgeOffset: 0,
                    // Re-running the matching engine on pull-to-refresh is the
                    // same trigger point as opening this screen (CLAUDE.md
                    // "Client-Side Matching Engine" trigger b) — just user-invoked.
                    // Guests just reload the public newest-listings feed.
                    onRefresh: () => context.read<HomeCubit>().refresh(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: <Widget>[
                        if (state.errorMessage != null)
                          SliverToBoxAdapter(
                            child: _ErrorBanner(message: state.errorMessage!),
                          )
                        else if (state.isLoading && state.listings.isEmpty)
                          const SliverToBoxAdapter(
                            child: HomeContentSkeleton(),
                          )
                        else if (state.listings.isEmpty && isGuest)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: Center(
                                child: _EmptyState(isGuest: isGuest),
                              ),
                            ),
                          )
                        else if (state.listings.isEmpty) ...[
                          // No compatible properties: still show the separate
                          // "Other listings" section below the empty state.
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xs,
                                bottom: AppSpacing.md,
                              ),
                              child: _EmptyState(
                                isGuest: isGuest,
                                onExploreOtherListings: _scrollToOtherListings,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: KeyedSubtree(
                              key: _otherListingsKey,
                              child: const OtherListingsSection(),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 400),
                          ),
                        ] else ...[
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 14),
                          ),
                          const SliverToBoxAdapter(child: RecommendedSection()),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 12),
                          ),
                          const SliverToBoxAdapter(child: NearbySection()),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 16),
                          ),
                          const SliverToBoxAdapter(
                            child: OtherListingsSection(),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isGuest,
    this.onExploreOtherListings,
  });

  final bool isGuest;
  final VoidCallback? onExploreOtherListings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.slate900.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              child: SizedBox(
                width: 150,
                height: 95,
                child: OverflowBox(
                  maxHeight: 150,
                  maxWidth: 150,
                  child: Lottie.asset(
                    'assets/images/no_match_placeholder.json',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                    repeat: true,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Lottie load error: $error');
                      return Center(
                        child: Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.home_work_outlined,
                            size: 40,
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isGuest ? 'No listings yet' : 'No matching properties yet',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              isGuest
                  ? 'Check back soon, or sign up to see the boarding houses that match you.'
                  : "We couldn't find properties that match your preferences right now. "
                      "You can update your preferences or check out other listings below.",
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: AppColors.slate500,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Left Button: Explore Other Listings
                Expanded(
                  child: Material(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: onExploreOtherListings ??
                          () {
                            final scrollable = Scrollable.maybeOf(context);
                            if (scrollable != null) {
                              scrollable.position.animateTo(
                                scrollable.position.pixels + 360,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 32,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.1,
                          ),
                        ),
                        child: const Text(
                          'Explore Other Listings',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Right Button: Update Preferences
                Expanded(
                  child: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () async {
                        if (isGuest) {
                          GuestAccessSheet.show(context);
                          return;
                        }
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => const EditConstraintsScreen(),
                          ),
                        );
                        if (changed == true && context.mounted) {
                          context.read<HomeCubit>().refresh();
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 32,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: const Text(
                          'Update Preferences',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.surface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.destructive.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.field),
          border: Border.all(
            color: AppColors.destructive.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.destructive, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body(
                  context,
                ).copyWith(color: AppColors.destructive),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
