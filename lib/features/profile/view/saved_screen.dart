import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../features/home/cubit/home_cubit.dart';
import '../../../features/home/model/listing.dart';
import '../../../features/home/widgets/listing_card_large.dart';
import '../../../features/home/widgets/nearby_section.dart'
    show openPropertyDetail;

class SavedScreen extends StatefulWidget {
  const SavedScreen({this.showBackButton = true, super.key});

  final bool showBackButton;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch the saved properties once on open (never from build()).
    context.read<HomeCubit>().loadSaved();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild only for the saved-tab fields, not every HomeState emission.
    context.select<HomeCubit, (List<Listing>, Set<String>, bool, bool)>(
      (c) => (
        c.state.savedListings,
        c.state.savedIds,
        c.state.isLoadingSaved,
        c.state.savedLoadFailed,
      ),
    );
    final state = context.read<HomeCubit>().state;
    // Unsaving is optimistic: the card leaves at once, and returns if the
    // write fails and is rolled back.
    final saved = [
      for (final l in state.savedListings)
        if (state.savedIds.contains(l.id)) l,
    ];
    final cubit = context.read<HomeCubit>();

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: Stack(
        children: <Widget>[
          // Subtle top-right gradient
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
                      AppColors.tenantFillCyan.withValues(alpha: 0.70),
                      AppColors.tenantFillCyan.withValues(alpha: 0.35),
                      AppColors.tenantFillCyan.withValues(alpha: 0.0),
                    ],
                    stops: const <double>[0.0, 0.45, 0.88],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  if (widget.showBackButton &&
                      Navigator.of(context).canPop()) ...[
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.appColors.fieldFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: context.appColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Properties you bookmarked for later',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.appColors.textSecondary,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (saved.isNotEmpty)
                    Text(
                      '${saved.length} ${saved.length == 1 ? 'property' : 'properties'}',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            // â”€â”€ Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: state.isLoadingSaved && state.savedListings.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.savedLoadFailed && state.savedListings.isEmpty
                  ? _ErrorState(onRetry: cubit.loadSaved)
                  : saved.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        100,
                      ),
                      itemCount: saved.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (ctx, i) {
                        final listing = saved[i].copyWith(isSaved: true);
                        return ListingCardLarge(
                          listing: listing,
                          onSavedToggle: () => cubit.toggleSaved(listing.id),
                          onTap: () => openPropertyDetail(
                            ctx,
                            cubit,
                            listing.id,
                            initialListing: listing,
                            initialPropertyDoc: listing.propertyDoc,
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

// Error state (with Retry)

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            "Couldn't load your saved properties.",
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              color: context.appColors.textSecondary,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// â”€â”€ Empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.appColors.fieldFill,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_outline_rounded,
              size: 36,
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No saved properties yet',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap the heart on any listing\nto save it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}


