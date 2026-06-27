import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/home_cubit.dart';
import '../model/listing.dart';
import '../model/listing_detail.dart';
import '../view/listing_detail_screen.dart';
import 'listing_card_large.dart';

/// "Recommended for you" horizontal scroll section.
class RecommendedSection extends StatelessWidget {
  const RecommendedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final listings =
        context.select<HomeCubit, List<Listing>>((c) => c.state.recommended);
    final cubit = context.read<HomeCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionHeader(title: 'Recommended for you', onSeeAll: () {}),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: listings.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (ctx, i) => ListingCardLarge(
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
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: AppTextStyles.link.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
