import '../../../core/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/ci_score_pill.dart';
import '../../../shared/widgets/constraint_check_row.dart';
import '../../../shared/widgets/guest_access_sheet.dart';
import '../../../shared/widgets/hero_icon_button.dart';
import '../../../shared/widgets/property_photo_carousel.dart';
import '../../inquiry/view/start_inquiry.dart';
import '../../matching/domain/entities/mismatch_reason.dart';
import '../../profile/view/edit_constraints_screen.dart';
import '../cubit/home_cubit.dart';

/// The detail-screen heart: filled destructive when saved. Rebuilds only when
/// this property's saved flag changes.
class _SaveHeart extends StatelessWidget {
  const _SaveHeart({
    required this.propertyId,
    required this.cubit,
    required this.onTap,
  });

  final String propertyId;
  final HomeCubit? cubit;
  final void Function(HomeCubit? cubit) onTap;

  @override
  Widget build(BuildContext context) {
    final cubit = this.cubit;
    Widget button(bool saved) => HeroIconButton(
      icon: saved ? Icons.favorite : Icons.favorite_border,
      iconColor: saved ? AppColors.destructive : null,
      tooltip: saved ? 'Remove from saved' : 'Save',
      onPressed: () => onTap(cubit),
    );
    if (cubit == null) return button(false);
    return BlocBuilder<HomeCubit, HomeState>(
      bloc: cubit,
      buildWhen: (a, b) =>
          a.savedIds.contains(propertyId) != b.savedIds.contains(propertyId),
      builder: (_, state) => button(state.savedIds.contains(propertyId)),
    );
  }
}

class PropertyDetailScreen extends StatelessWidget {
  const PropertyDetailScreen({
    required this.property,
    this.isGuest = false,
    this.onPreferencesSaved,
    this.homeCubit,
    super.key,
  });

  final Map<String, dynamic> property;
  final bool isGuest;

  /// Called after the tenant saves new preferences from this screen (which
  /// re-runs matching), so the opener can refresh its feed.
  final VoidCallback? onPreferencesSaved;

  /// Owns the saved-listing (heart) state. Pushed routes sit outside the
  /// shell's providers, so the opener passes it in; null leaves the heart
  /// inert (previews).
  final HomeCubit? homeCubit;

  Future<void> _editPreferences(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const EditConstraintsScreen()),
    );
    if (saved == true) {
      onPreferencesSaved?.call();
      // A view-only listing may match now; leave this stale detail so the
      // refreshed Search shows it as a normal match (or still as a non-match).
      if (property['isNonMatch'] == true && context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// All photos of the property, cover first; falls back to the single
  /// `photoUrl` for maps built without a `photos` list.
  static List<String> _photosOf(Map<String, dynamic> property) {
    final photos = property['photos'];
    if (photos is List && photos.isNotEmpty) {
      return [
        for (final p in photos)
          if (p is String && p.isNotEmpty) p,
      ];
    }
    final single = property['photoUrl'] as String?;
    return single == null || single.isEmpty ? const [] : [single];
  }

  void _guardGuestAction(BuildContext context, VoidCallback action) {
    if (isGuest) {
      GuestAccessSheet.show(context);
      return;
    }
    action();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutside = property['isOutsidePreference'] == true;
    final bool isNonMatch = property['isNonMatch'] == true;
    final reasons =
        (property['mismatchReasons'] as List?)?.cast<MismatchReason>() ??
        const <MismatchReason>[];
    final int bScore = (property['bScore'] as num).toInt();
    final bool ownerVerified = property['isVerified'] == true;
    final bool canInquire = bScore == 1;
    final int seed = (property['propertyId'] as String).hashCode % 5 + 1;
    final tenantCi = property['tenantCi'] as num?;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: Column(
        children: [
          // View-only: the listing fails the saved preferences.
          if (isNonMatch)
            Container(
              color: AppColors.amberFill,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                16,
                8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.amberPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Doesn't match your preferences (view only)",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.amberText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Outside preferences banner
          if (isOutside)
            Container(
              color: AppColors.amberFill,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                16,
                8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.amberPrimary,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Outside your session filter',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amberText,
                          ),
                        ),
                        Text(
                          [
                            if ((property['distanceExcess'] ?? 0) > 0)
                              'Distance is ${property['distanceExcess']} km over limit',
                            if ((property['budgetExcess'] ?? 0) > 0)
                              'Budget is ₱${property['budgetExcess']} over limit',
                            if ((property['distanceExcess'] ?? 0) == 0 &&
                                (property['budgetExcess'] ?? 0) == 0)
                              'Budget is within range',
                          ].join(' · '),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Scrollable content
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Hero image with back + heart buttons
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 240,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PropertyPhotoCarousel(
                              seed: seed,
                              photos: _photosOf(property),
                            ),
                            if (isOutside)
                              IgnorePointer(
                                child: Container(
                                  color: AppColors.amberFill.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        top:
                            MediaQuery.of(context).padding.top +
                            (isOutside ? 0 : 8),
                        left: 8,
                        child: HeroIconButton(
                          icon: Icons.arrow_back_ios_new,
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Positioned(
                        top:
                            MediaQuery.of(context).padding.top +
                            (isOutside ? 0 : 8),
                        right: 8,
                        child: _SaveHeart(
                          propertyId: property['propertyId'] as String,
                          cubit: homeCubit,
                          onTap: (cubit) => _guardGuestAction(
                            context,
                            () => cubit?.toggleSaved(
                              property['propertyId'] as String,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + address + price
                        Text(
                          property['title'] as String,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          property['address'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '₱${property['monthlyRent']} / month',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.appColors.textPrimary,
                          ),
                        ),

                        SizedBox(height: 20),

                        // Owner card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.appColors.fieldFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.appColors.fieldBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.tenantFillBlue,
                                child: Text(
                                  property['ownerInitials'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.tenantTextDeep,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    property['ownerName'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: context.appColors.textPrimary,
                                    ),
                                  ),
                                  if (ownerVerified)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.primaryTeal,
                                          size: 13,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'Verified Owner',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryTeal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  Text(
                                    'Member since ${property['memberSince']} · ${property['propertyCount']} properties',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.appColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        // House rules (non-outside)
                        if (!isOutside) ...[
                          Text(
                            'House Rules',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 12),
                          _RuleRow(
                            label: 'Gender policy',
                            value: property['allowedGender'] as String,
                          ),
                          _RuleRow(
                            label: 'Smoking',
                            value: property['smokingAllowed'] == true
                                ? 'Allowed'
                                : 'Not allowed',
                          ),
                          _RuleRow(
                            label: 'Curfew',
                            value: formatCurfew(
                              property['curfewHours'] as num?,
                            ),
                          ),
                          SizedBox(height: 16),
                          if (isGuest)
                            Text(
                              'Sign up to see your matches',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.appColors.textSecondary,
                              ),
                            )
                          else if (!isNonMatch && tenantCi != null) ...[
                            Row(
                              children: [
                                CiScorePill(score: tenantCi.toDouble()),
                                SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.appColors.fieldFill,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: context.appColors.fieldBorder,
                                    ),
                                  ),
                                  child: Text(
                                    '#${property['tenantRank']} Rank',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: context.appColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],

                        // Why a view-only listing does not match.
                        if (isNonMatch) ...[
                          const SizedBox(height: 16),
                          Text(
                            "Why it doesn't match",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final r in reasons)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.matchMedium,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      r.detailLabel,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context.appColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],

                        // Compatibility check (outside prefs)
                        if (isOutside) ...[
                          Text(
                            'Compatibility check',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 12),
                          ConstraintCheckRow(
                            label: 'Monthly rent',
                            value:
                                '₱${property['monthlyRent']} — within budget',
                            isPassing: (property['budgetExcess'] ?? 0) == 0,
                          ),
                          ConstraintCheckRow(
                            label: 'Distance',
                            value:
                                '${property['distance']} km — +${property['distanceExcess']} km over limit',
                            isPassing: (property['distanceExcess'] ?? 0) == 0,
                          ),
                          ConstraintCheckRow(
                            label: 'Gender policy',
                            value: '${property['allowedGender']} — matches',
                            isPassing: true,
                          ),
                        ],

                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canInquire && !isOutside && !isNonMatch)
                AppButton(
                  label: 'Send Inquiry',
                  color: AppColors.ink,
                  onPressed: () => _guardGuestAction(
                    context,
                    () => startInquiry(
                      context,
                      propertyId: property['propertyId'] as String,
                      matchId: property['matchId'] as String?,
                    ),
                  ),
                ),
              // Rule 2: no Send Inquiry for a non-match (absent, not disabled).
              if (isNonMatch)
                AppButton(
                  label: 'Update my preferences',
                  color: AppColors.ink,
                  isOutlined: true,
                  onPressed: () => _editPreferences(context),
                ),
              if (isOutside) ...[
                if (canInquire) ...[
                  AppButton(
                    label: 'Send Inquiry Anyway',
                    color: AppColors.ink,
                    onPressed: () => _guardGuestAction(
                      context,
                      () => startInquiry(
                        context,
                        propertyId: property['propertyId'] as String,
                        matchId: property['matchId'] as String?,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
                // Flagged listings already pass the *saved* preferences (the
                // flag comes from Search's session filter), so this opens
                // the saved preferences rather than implying they're exceeded.
                AppButton(
                  label: 'Edit My Saved Preferences',
                  color: AppColors.ink,
                  isOutlined: true,
                  onPressed: () => _guardGuestAction(
                    context,
                    () => _editPreferences(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: context.appColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: context.appColors.fieldBorder),
      ],
    );
  }
}
