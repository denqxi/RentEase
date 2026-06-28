import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/listing_card_row.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/model/listing.dart';
import '../../home/model/listing_detail.dart';
import '../../home/view/listing_detail_screen.dart';

/// Matches tab — all listings sorted by match score.
class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final listings =
        context.select<HomeCubit, List<Listing>>((c) => c.state.allByMatch);
    final cubit = context.read<HomeCubit>();

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Matches', style: AppTextStyles.title(context)),
                    SizedBox(height: 4),
                    Text(
                      'Homes sorted by how well they match you',
                      style: AppTextStyles.body(context),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList.separated(
                itemCount: listings.length,
                separatorBuilder: (_, _) =>
                    SizedBox(height: AppSpacing.sm),
                itemBuilder: (ctx, i) => ListingCardRow(
                  listing: listings[i],
                  onSavedToggle: () => cubit.toggleSaved(listings[i].id),
                  onTap: () => Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ListingDetailScreen(detail: ListingDetail.sample),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],
        ),
      ),
    );
  }
}
