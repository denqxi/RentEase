import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../registration/model/user_role.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_header.dart';
import '../widgets/nearby_section.dart';
import '../widgets/recommended_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isGuest = context.select<ProfileCubit, bool>(
      (c) => c.state.userRole == UserRole.guest,
    );

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          buildWhen: (prev, curr) =>
              prev.isLoading != curr.isLoading ||
              prev.errorMessage != curr.errorMessage ||
              prev.listings.isEmpty != curr.listings.isEmpty,
          builder: (context, state) {
            return RefreshIndicator(
              // Re-running the matching engine on pull-to-refresh is the
              // same trigger point as opening this screen (CLAUDE.md
              // "Client-Side Matching Engine" trigger b) — just user-invoked.
              // Guests just reload the public newest-listings feed.
              onRefresh: () => context.read<HomeCubit>().refresh(),
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: HomeHeader(
                      userName: isGuest
                          ? 'Guest'
                          : firstNameOf(
                              context.select<ProfileCubit, String>(
                                (c) => c.state.fullName,
                              ),
                            ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sm),
                  ),
                  if (state.errorMessage != null)
                    SliverToBoxAdapter(
                      child: _ErrorBanner(message: state.errorMessage!),
                    )
                  else if (state.isLoading && state.listings.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.listings.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(isGuest: isGuest),
                    )
                  else ...[
                    const SliverToBoxAdapter(child: RecommendedSection()),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.lg),
                    ),
                    const SliverToBoxAdapter(child: NearbySection()),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.lg),
                    ),
                  ],
                ],
              ),
            );
          },
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
