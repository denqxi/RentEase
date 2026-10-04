import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/admin_unlisted_notice.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../../shared/widgets/pending_listing_banner.dart';
import '../../auth/presentation/current_uid.dart';
import '../../owner_onboarding/view/add_property_screen.dart';
import '../cubit/owner_properties_cubit.dart';
import '../data/repositories/owner_property_repository_impl.dart';
import 'edit_property_screen.dart';

/// "My properties" — the owner's real listings, live from Firestore, with
/// availability (list / pause / mark booked / relist) and editing.
class OwnerPropertiesScreen extends StatelessWidget {
  const OwnerPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = currentUidOrNull(context);
    if (uid == null) {
      return const _PropertiesScaffold(
        body: Center(child: Text('Sign in to manage your properties.')),
      );
    }
    return BlocProvider(
      create: (_) => OwnerPropertiesCubit(
        ownerId: uid,
        repository: OwnerPropertyRepositoryImpl(),
      ),
      child: const _OwnerPropertiesView(),
    );
  }
}

class _PropertiesScaffold extends StatelessWidget {
  const _PropertiesScaffold({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        title: Text(
          'My properties',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AddPropertyScreen()),
            ),
            icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
            label: const Text(
              'Add',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _OwnerPropertiesView extends StatelessWidget {
  const _OwnerPropertiesView();

  Future<void> _edit(BuildContext context, PropertyDoc property) async {
    final cubit = context.read<OwnerPropertiesCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditPropertyScreen(
          property: property,
          onSave: (fields) =>
              cubit.updateProperty(property.propertyId, fields),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OwnerPropertiesCubit, OwnerPropertiesState>(
      listenWhen: (prev, curr) =>
          curr.errorMessage != null && prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppColors.destructive,
          ),
        );
        context.read<OwnerPropertiesCubit>().clearError();
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const _PropertiesScaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final cubit = context.read<OwnerPropertiesCubit>();
        return _PropertiesScaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.showPendingBanner) ...[
                  PendingListingBanner(status: state.verificationStatus),
                  SizedBox(height: AppSpacing.md),
                ],
                // ── Metrics ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Listings',
                        value: '${state.properties.length}',
                        color: AppColors.accent,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _MetricCard(
                        label: 'Available',
                        value: '${state.availableCount}',
                        color: AppColors.matchHigh,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _MetricCard(
                        label: 'Open inquiries',
                        value: '${state.openInquiries}',
                        color: AppColors.matchMedium,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Your properties',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                if (state.properties.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Text(
                      'No listings yet. Tap "Add" to create your first '
                      'property.',
                      style: AppTextStyles.body(context),
                    ),
                  ),
                for (final p in state.properties)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _PropertyCard(
                      property: p,
                      onStatusChange: (status) =>
                          cubit.setVacancy(p.propertyId, status),
                      onEdit: () => _edit(context, p),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption(context)),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    required this.onStatusChange,
    required this.onEdit,
  });

  final PropertyDoc property;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final int seed = property.propertyId.hashCode % 5 + 1;
    final String status = property.vacancyStatus;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo ────────────────────────────────────────────────────
          SizedBox(
            height: 110,
            width: double.infinity,
            child: ListingImagePlaceholder(
              seed: seed,
              photoUrl: property.photos.isEmpty ? null : property.photos.first,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${property.address} · ₱${property.monthlyRent}/mo · '
                  '${property.amenityScore ?? property.amenityList.length} amenities',
                  style: AppTextStyles.caption(context),
                ),
                SizedBox(height: AppSpacing.sm + 2),

                // ── Availability — explicit labeled selector ────────────
                Text(
                  'AVAILABILITY',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: context.appColors.textSecondary,
                  ),
                ),
                SizedBox(height: 6),
                if (property.adminUnlisted)
                  const AdminUnlistedNotice()
                else
                  Row(
                    children: [
                      _StatusChip(
                        label: 'Available',
                        color: AppColors.matchHigh,
                        isSelected: status == 'available',
                        onTap: () => onStatusChange('available'),
                      ),
                      SizedBox(width: 8),
                      _StatusChip(
                        label: 'Pending',
                        color: AppColors.matchMedium,
                        isSelected: status == 'pending',
                        onTap: () => onStatusChange('pending'),
                      ),
                      SizedBox(width: 8),
                      _StatusChip(
                        label: 'Booked',
                        color: context.appColors.textSecondary,
                        isSelected: status == 'booked',
                        onTap: () => onStatusChange('booked'),
                      ),
                    ],
                  ),
                SizedBox(height: AppSpacing.sm + 2),

                AppButton(
                  label: 'Edit details',
                  variant: AppButtonVariant.outline,
                  isSmall: true,
                  onPressed: onEdit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tap-to-set status chip. The selected status is filled with its color;
/// unselected chips stay neutral so the current state is unmistakable.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : context.appColors.fieldFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : context.appColors.fieldBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check_rounded, size: 13, color: AppColors.onInk),
                SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.onInk
                      : context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
