import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/listing_card_row.dart';
import '../cubit/home_cubit.dart';
import '../model/listing.dart';
import '../view/property_detail_screen.dart';

/// "Nearby homes" vertical list section on the home screen.
class NearbySection extends StatelessWidget {
  const NearbySection({super.key});

  @override
  Widget build(BuildContext context) {
    final listings =
        context.select<HomeCubit, List<Listing>>((c) => c.state.nearby);
    final cubit = context.read<HomeCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'Nearby homes',
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: listings.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (ctx, i) => ListingCardRow(
            listing: listings[i],
            onSavedToggle: () => cubit.toggleSaved(listings[i].id),
            onTap: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                builder: (_) => PropertyDetailScreen(
                  property: MockData.properties[i % MockData.properties.length],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
