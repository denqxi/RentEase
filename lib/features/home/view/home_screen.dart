import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/guest_access_sheet.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../registration/model/user_role.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_header.dart';
import '../widgets/nearby_section.dart';
import '../widgets/other_listings_section.dart';
import '../widgets/recommended_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
    final inquiryCount = profileState?.inquiryCount ?? 0;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            // Fixed top bar — stays stationary on pull down & scroll
            ColoredBox(
              color: context.appColors.surface,
              child: HomeHeader(
                userName: isGuest
                    ? 'Guest'
                    : (firstName.isEmpty ? 'Tenant' : firstName),
                photoUrl: photoUrl,
                isGuest: isGuest,
                hasUnreadInquiries: !isGuest && inquiryCount > 0,
                onInquiryTap: () {
                  if (isGuest) {
                    GuestAccessSheet.show(context);
                  } else {
                    Navigator.of(context).pushNamed(AppRouter.tenantInquiries);
                  }
                },
              ),
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
                    backgroundColor: Colors.white,
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
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (state.listings.isEmpty && isGuest)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(isGuest: isGuest),
                          )
                        else if (state.listings.isEmpty) ...[
                          // No compatible properties: still show the separate
                          // "Other listings" section below the empty state.
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg,
                              ),
                              child: _EmptyState(isGuest: isGuest),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: OtherListingsSection(),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                        ] else ...[
                          const SliverToBoxAdapter(child: RecommendedSection()),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: AppSpacing.lg),
                          ),
                          const SliverToBoxAdapter(child: NearbySection()),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: AppSpacing.lg),
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isGuest});

  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 48,
            color: context.appColors.hint,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            isGuest ? 'No listings yet' : 'No compatible properties yet',
            style: AppTextStyles.body(
              context,
            ).copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            isGuest
                ? 'Check back soon, or sign up to see the boarding houses '
                      'that match you.'
                : 'Try widening your budget, distance, or other preferences '
                      'from your profile — or check back once more listings '
                      'are verified.',
            style: AppTextStyles.body(
              context,
            ).copyWith(color: context.appColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
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
            Icon(Icons.error_outline, color: AppColors.destructive, size: 18),
            SizedBox(width: AppSpacing.sm),
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
