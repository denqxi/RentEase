import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../matching/domain/entities/mismatch_reason.dart';
import '../../shell/cubit/shell_cubit.dart';
import '../cubit/home_cubit.dart';
import '../view/property_detail_screen.dart';

/// "Other listings": view-only listings that do not match all of the
/// tenant's saved preferences. Always a separate section below the
/// Ci-ranked ones - never mixed in, no Ci/percent, no Send Inquiry (the
/// detail screen offers "Update my preferences" instead). Hidden for guests,
/// while loading, on failure (small retry line) and when there are none.
class OtherListingsSection extends StatelessWidget {
  const OtherListingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<HomeCubit, HomeState>((c) => c.state);
    if (state.isGuest) return const SizedBox.shrink();

    if (state.othersFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                "Couldn't load other listings.",
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: context.read<HomeCubit>().retryOthers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final others = state.otherListings;
    if (others.isEmpty) return const SizedBox.shrink();

    final cubit = context.read<HomeCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Other listings',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  cubit.requestSearchWithNonMatches();
                  context.read<ShellCubit>().selectTab(ShellTab.search);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'See more',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            "These don't match all of your preferences",
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: context.appColors.textSecondary,
            ),
          ),
        ),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: others.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (ctx, i) => OtherListingCard(
            property: others[i],
            isSaved: state.savedIds.contains(others[i]['propertyId']),
            onSavedToggle: () =>
                cubit.toggleSaved(others[i]['propertyId'] as String),
            onTap: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                // The loaded map is already the full detail shape.
                builder: (_) => PropertyDetailScreen(
                  property: others[i],
                  homeCubit: cubit,
                  onPreferencesSaved: cubit.refresh,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Muted, view-only card: reasons text and an amber label; no Ci, percent or
/// inquiry affordance.
class OtherListingCard extends StatelessWidget {
  const OtherListingCard({
    required this.property,
    required this.onTap,
    this.isSaved = false,
    this.onSavedToggle,
    super.key,
  });

  final Map<String, dynamic> property;
  final VoidCallback onTap;
  final bool isSaved;

  /// Null hides the heart (guests have no Other listings anyway).
  final VoidCallback? onSavedToggle;

  String _fmt(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final id = property['propertyId'] as String;
    final rent = (property['monthlyRent'] as num).toInt();
    final reasons =
        (property['mismatchReasons'] as List?)?.cast<MismatchReason>() ??
        const <MismatchReason>[];

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: 0.75,
        child: Container(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 72,
                height: 72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListingImagePlaceholder(
                    seed: id.hashCode % 5 + 1,
                    photoUrl: property['photoUrl'] as String?,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      property['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₱${_fmt(rent)}/mo',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      "Doesn't match your preferences",
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amberText,
                      ),
                    ),
                    if (reasons.isNotEmpty)
                      Text(
                        reasons.take(2).map((r) => r.shortLabel).join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (onSavedToggle != null)
                IconButton(
                  tooltip: isSaved ? 'Remove from saved' : 'Save',
                  onPressed: onSavedToggle,
                  icon: Icon(
                    isSaved ? Icons.favorite : Icons.favorite_border,
                    color: isSaved
                        ? AppColors.destructive
                        : context.appColors.textSecondary,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
