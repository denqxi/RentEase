import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/models/models.dart';
import '../../../shared/widgets/guest_access_sheet.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../registration/model/user_role.dart';
import '../cubit/home_cubit.dart';
import '../model/listing.dart';
import '../view/property_detail_screen.dart';
import 'listing_card_large.dart';

/// Opens property details immediately without blocking network requests,
/// displaying initial in-memory data instantly with zero latency.
void openPropertyDetail(
  BuildContext context,
  HomeCubit cubit,
  String propertyId, {
  Listing? initialListing,
  PropertyDoc? initialPropertyDoc,
  Map<String, dynamic>? initialProperty,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PropertyDetailScreen(
        propertyId: propertyId,
        initialListing: initialListing,
        initialPropertyDoc: initialPropertyDoc,
        property: initialProperty,
        isGuest: cubit.state.isGuest,
        homeCubit: cubit,
        onPreferencesSaved: cubit.refresh,
      ),
    ),
  );
}

/// "Compatible properties" vertical list section on the home screen — sorted
/// by TOPSIS Ci score, styled with the modern owner card aesthetic.
class NearbySection extends StatelessWidget {
  const NearbySection({super.key});

  @override
  Widget build(BuildContext context) {
    final top3Ids = context.select<HomeCubit, Set<String>>(
      (c) => c.state.recommended.take(3).map((l) => l.id).toSet(),
    );
    final allNearby = context.select<HomeCubit, List<Listing>>(
      (c) => c.state.nearby,
    );
    final listings = allNearby.where((l) => !top3Ids.contains(l.id)).toList();
    if (listings.isEmpty) return const SizedBox.shrink();

    final cubit = context.read<HomeCubit>();
    final isGuest = context.select<ProfileCubit, bool>(
      (c) => c.state.userRole == UserRole.guest,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isGuest ? 'Newest listings' : 'Compatible properties',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                  letterSpacing: -0.2,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                isGuest
                    ? 'Sign up to see your matches'
                    : 'Properties that match all your preferences.',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: context.appColors.textSecondary,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: listings.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (ctx, i) => ListingCardLarge(
            listing: listings[i],
            isGuest: isGuest,
            onSavedToggle: () {
              if (isGuest) {
                GuestAccessSheet.show(ctx);
                return;
              }
              cubit.toggleSaved(listings[i].id);
            },
            onTap: () => openPropertyDetail(
              ctx,
              cubit,
              listings[i].id,
              initialListing: listings[i],
              initialPropertyDoc: listings[i].propertyDoc,
            ),
          ),
        ),
      ],
    );
  }
}
