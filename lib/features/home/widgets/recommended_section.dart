import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/guest_access_sheet.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../registration/model/user_role.dart';
import '../cubit/home_cubit.dart';
import '../model/listing.dart';
import 'listing_card_large.dart';
import 'nearby_section.dart' show openPropertyDetail;

/// "Recommended for you" top 3 property matches section with synchronized
/// page indicator dots matching the owner design style.
class RecommendedSection extends StatefulWidget {
  const RecommendedSection({super.key});

  @override
  State<RecommendedSection> createState() => _RecommendedSectionState();
}

class _RecommendedSectionState extends State<RecommendedSection> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Select the stable inputs: `recommended` builds a new sorted list on
    // every call, so selecting it directly rebuilt on every emission.
    context.select<HomeCubit, List<Listing>>((c) => c.state.listings);
    context.select<HomeCubit, bool>((c) => c.state.isGuest);
    final cubit = context.read<HomeCubit>();
    final allListings = cubit.state.recommended;
    final isGuest = context.select<ProfileCubit, bool>(
      (c) => c.state.userRole == UserRole.guest,
    );

    // Limit to top 3 matches per user instruction
    final top3 = allListings.take(3).toList();
    if (top3.isEmpty) return const SizedBox.shrink();

    final totalDots = top3.length;
    final activeDot = _currentPage.clamp(0, totalDots - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Title and Subtitle matching the design reference image
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGuest ? 'Just listed' : 'Recommended for you',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textSecondary,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isGuest
                        ? 'Top 3 featured properties'
                        : 'Your top 3 property matches',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                      letterSpacing: -0.2,
                      height: 1.15,
                    ),
                  ),
                ],
              ),

              // Page indicator dots (active teal, inactive light grey)
              if (totalDots > 1)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(totalDots, (index) {
                    final isActive = index == activeDot;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.slate200,
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 308,
          child: PageView.builder(
            controller: _pageController,
            clipBehavior: Clip.none,
            padEnds: true,
            itemCount: top3.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (ctx, i) {
              final listing = top3[i];
              return Padding(
                padding: const EdgeInsets.only(
                  left: 6,
                  right: 6,
                  bottom: 8,
                ),
                child: ListingCardLarge(
                  listing: listing,
                  isGuest: isGuest,
                  onSavedToggle: () {
                    if (isGuest) {
                      GuestAccessSheet.show(ctx);
                      return;
                    }
                    cubit.toggleSaved(listing.id);
                  },
                  onTap: () => openPropertyDetail(
                    ctx,
                    cubit,
                    listing.id,
                    initialListing: listing,
                    initialPropertyDoc: listing.propertyDoc,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
