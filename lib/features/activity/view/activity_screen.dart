import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/activity_cubit.dart';
import '../widgets/activity_tile.dart';

/// Alerts tab — chronological activity feed with "Mark all read".
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ActivityCubit>().state;
    final cubit = context.read<ActivityCubit>();
    final items = state.items;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: <Widget>[
                    Text('Activity', style: AppTextStyles.title(context)),
                    const Spacer(),
                    GestureDetector(
                      onTap: cubit.markAllRead,
                      child: Text(
                        'Mark all read',
                        style: AppTextStyles.link(context).copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        state.errorMessage!,
                        style: AppTextStyles.caption(context),
                      ),
                      TextButton(
                        onPressed: cubit.retry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    "You're all caught up. New alerts will show here.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption(context),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => ActivityTile(item: items[i]),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
