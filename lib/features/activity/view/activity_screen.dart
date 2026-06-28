import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/activity_cubit.dart';
import '../model/activity_item.dart';
import '../widgets/activity_tile.dart';

/// Alerts tab — chronological activity feed with "Mark all read".
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context
        .select<ActivityCubit, List<ActivityItem>>((c) => c.state.items);
    final cubit = context.read<ActivityCubit>();

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
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => ActivityTile(item: items[i]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],
        ),
      ),
    );
  }
}
