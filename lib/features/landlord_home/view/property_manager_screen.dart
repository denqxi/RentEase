import 'dart:ui' show ImageFilter;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/cloudinary_config.dart';
import '../../../core/firestore/models/models.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../owner_onboarding/view/create_listing_wizard_screen.dart';
import '../../owner_onboarding/widgets/listing_form_widgets.dart';
import '../../uploads/data/repositories/cloudinary_image_upload_repository.dart';
import '../../uploads/domain/entities/uploaded_image.dart';
import '../cubit/landlord_home_cubit.dart';
import '../widgets/edit_property_sheet.dart';
import 'edit_entire_property_screen.dart';
import 'property_reviews_screen.dart';

// Compiled once instead of on every call.
final RegExp _kThousandsRe = RegExp(r'(\d)(?=(\d{3})+(?!\d))');

/// Screen displayed when clicking an owner property card.
///
/// Supports two distinct modes:
/// 1. Entire Property / Single Room Overview: Read-only overview with live status
///    toggle (with confirmation), amenities, rules/specs, compatible tenants list
///    with invitation actions, and an Edit button navigating to [EditEntirePropertyScreen].
/// 2. Multi-Unit Property: Room unit manager with per-unit occupancy toggles.
class PropertyManagerScreen extends StatefulWidget {
  const PropertyManagerScreen({
    required this.initialProperty,
    required this.initialRooms,
    this.isSingleRoomView = false,
    super.key,
  });

  final PropertyDoc initialProperty;
  final List<PropertyDoc> initialRooms;
  final bool isSingleRoomView;

  @override
  State<PropertyManagerScreen> createState() => _PropertyManagerScreenState();
}

class _PropertyManagerScreenState extends State<PropertyManagerScreen> {

  Future<void> _selectRoomStatus(
    BuildContext context,
    PropertyDoc room,
    String targetStatus,
    LandlordHomeCubit cubit,
  ) async {
    final currentStatus = room.vacancyStatus.isNotEmpty
        ? room.vacancyStatus
        : (room.isAvailable ? 'available' : 'booked');
    if (targetStatus == currentStatus) return;

    final targetLabel =
        targetStatus == 'available' ? 'Available' : 'Occupied';

    final explanation = targetStatus == 'available'
        ? 'Marking this room as Available will display it in tenant search results and allow compatible tenants to send inquiries.'
        : 'Marking this room as Occupied will hide it from public search results and prevent new tenant inquiries.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Change Status to $targetLabel?',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          explanation,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            color: AppColors.slate600,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  elevation: 0,
                  minimumSize: const Size(110, 42),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await cubit.setVacancy(room.propertyId, targetStatus);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room status updated to $targetLabel.'),
            backgroundColor: AppColors.slate900,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    }
  }

  Widget _buildMultiRoomPropertyTypeSvg({
    double size = 20,
    Color color = AppColors.slate900,
  }) {
    return SvgPicture.string(
      '''<svg xmlns="http://www.w3.org/2000/svg" width="$size" height="$size" viewBox="0 0 24 24" fill="none" stroke="#0F172A" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3 21l18 0" />
  <path d="M5 21v-14l8 -4v18" />
  <path d="M19 21v-10l-6 -4" />
  <path d="M9 9l0 .01" />
  <path d="M9 12l0 .01" />
  <path d="M9 15l0 .01" />
  <path d="M9 18l0 .01" />
</svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  void _openEditInfo(
    BuildContext context,
    PropertyDoc property,
    List<PropertyDoc> rooms,
    LandlordHomeCubit cubit,
  ) {
    final buildingName = (property.propertyName?.trim().isNotEmpty ?? false)
        ? property.propertyName!.trim()
        : property.title;
    final buildingType = property.propertyType ?? 'Boarding House';
    final location = LatLng(property.location.latitude, property.location.longitude);
    final coverSource = rooms.firstWhere(
      (r) => r.propertyCoverPhoto != null && r.propertyCoverPhoto!.trim().isNotEmpty,
      orElse: () => property,
    );
    final initialCoverUrl = coverSource.effectiveBuildingCoverPhoto;
    final initialCoverPublicId = coverSource.propertyCoverPublicId ??
        (coverSource.photoPublicIds.isNotEmpty
            ? coverSource.photoPublicIds.first
            : '');

    showEditPropertySheet(
      context: context,
      initialName: buildingName,
      initialType: buildingType,
      initialAddress: property.address,
      initialLocation: location,
      initialCoverPhotoUrl: initialCoverUrl,
      initialCoverPublicId: initialCoverPublicId,
      onSave: ({
        required String name,
        required String type,
        required String address,
        required LatLng location,
        coverPhoto,
      }) async {
        final updates = <String, dynamic>{
          'propertyName': name,
          'propertyType': type,
          'address': address,
          'location': GeoPoint(location.latitude, location.longitude),
          if (coverPhoto != null) ...{
            'propertyCoverPhoto': coverPhoto.url,
            'propertyCoverPublicId': coverPhoto.publicId,
          },
        };
        for (final r in rooms) {
          await cubit.updateProperty(r.propertyId, updates);
        }
      },
    );
  }

  void _openEditEntireProperty(
    BuildContext context,
    PropertyDoc property,
    LandlordHomeCubit cubit, {
    int initialTabIndex = 0,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditEntirePropertyScreen(
          property: property,
          initialTabIndex: initialTabIndex,
          onSave: (fields) => cubit.updateProperty(property.propertyId, fields),
        ),
      ),
    );
  }

  void _addUnit(BuildContext context, PropertyDoc property) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateListingWizardScreen(addRoomTo: property),
      ),
    );
  }

  void _editRoom(
    BuildContext context,
    PropertyDoc room,
    LandlordHomeCubit cubit,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: PropertyManagerScreen(
            initialProperty: room,
            initialRooms: [room],
            isSingleRoomView: true,
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveListingButton(
    BuildContext context,
    List<PropertyDoc> rooms,
    LandlordHomeCubit cubit,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.redFill50,
          highlightColor: AppColors.redFill50,
          onTap: () => _handleRemoveListing(context, rooms, cubit),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.destructive,
                ),
                SizedBox(width: 6),
                Text(
                  'Remove Listing',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.destructive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRemoveListing(
    BuildContext context,
    List<PropertyDoc> rooms,
    LandlordHomeCubit cubit,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    // 1. Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.redFill50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.destructive,
                  size: 22,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Remove This Listing?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Are you sure you want to remove this listing? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.slate500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: AppColors.surface,
                    elevation: 2,
                    shadowColor: AppColors.destructive.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                  child: const Text(
                    'Remove Listing',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.slate900,
                    side: const BorderSide(color: AppColors.slate200, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // 2. Removing Process (Loading Dialog)
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Removing listing...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Please wait a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await Future.wait([
        Future<void>.delayed(const Duration(milliseconds: 600)),
        Future(() async {
          for (final r in rooms) {
            await cubit.deleteProperty(r.propertyId);
          }
        }),
      ]);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.red600,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    // Close loading dialog
    Navigator.of(context, rootNavigator: true).pop();

    // 3. Success Message Dialog
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.green100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.green600,
                  size: 24,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Listing Removed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The listing has been successfully removed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.slate500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    widget.isSingleRoomView
                        ? 'Back to Property Management'
                        : 'Back to My Listings',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LandlordHomeCubit>();

    return BlocBuilder<LandlordHomeCubit, LandlordHomeState>(
      // Only `properties` is read below; skip rebuilding the whole screen for
      // unrelated emissions (tenants, search query, loading flags).
      buildWhen: (prev, curr) => prev.properties != curr.properties,
      builder: (context, state) {
        final propId = widget.initialProperty.propertyId;
        final parentId = widget.initialProperty.parentPropertyId;

        final liveRooms = state.properties.where((p) {
          if (!widget.isSingleRoomView &&
              parentId != null &&
              parentId.isNotEmpty) {
            return p.parentPropertyId == parentId;
          }
          return p.propertyId == propId;
        }).toList();

        final currentProperty = liveRooms.isNotEmpty
            ? liveRooms.first
            : widget.initialProperty;
        final currentRooms = liveRooms.isNotEmpty
            ? liveRooms
            : widget.initialRooms;

        final availableCount = currentRooms.where((r) => r.isAvailable).length;
        final displayName = widget.isSingleRoomView
            ? ((currentProperty.roomName?.trim().isNotEmpty ?? false)
                ? currentProperty.roomName!.trim()
                : currentProperty.title)
            : ((currentProperty.propertyName?.trim().isNotEmpty ?? false)
                ? currentProperty.propertyName!.trim()
                : currentProperty.title);
        final displayType = (currentProperty.propertyType?.trim().isNotEmpty ?? false)
            ? currentProperty.propertyType!.trim()
            : (currentProperty.isRoom ? 'Boarding House' : 'Apartment');
        final int seed = currentProperty.propertyId.hashCode % 5 + 1;
        final showSingleOverview =
            !currentProperty.isRoom || widget.isSingleRoomView;

        return Scaffold(
          backgroundColor: context.appColors.surface,
          appBar: AppBar(
            backgroundColor: context.appColors.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            leadingWidth: 54,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.slate200.withValues(alpha: 0.6),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.slate900.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: AppColors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: context.appColors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            titleSpacing: 10,
            centerTitle: false,
            title: Text(
              widget.isSingleRoomView
                  ? 'Room Management'
                  : 'Property Management',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.appColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.sm),

                        if (showSingleOverview) ...[
                          // ── OVERVIEW FOR ENTIRE PROPERTY / SINGLE ROOM ───────
                          _EntirePropertyPhotoCarousel(
                            property: currentProperty,
                            seed: seed,
                            cubit: cubit,
                          ),
                          const SizedBox(height: 14),

                          _EntirePropertyMainCard(
                            property: currentProperty,
                            displayName: displayName,
                            displayType: displayType,
                            cubit: cubit,
                            onEdit: () => _openEditEntireProperty(
                              context,
                              currentProperty,
                              cubit,
                            ),
                          ),
                          const SizedBox(height: 14),

                          _ExpandableRentSection(
                            property: currentProperty,
                            cubit: cubit,
                          ),
                          const SizedBox(height: 12),

                          _ExpandableRulesSection(
                            property: currentProperty,
                            cubit: cubit,
                          ),
                          const SizedBox(height: 12),

                          _ExpandableAmenitiesSection(
                            property: currentProperty,
                            cubit: cubit,
                          ),
                          const SizedBox(height: 14),

                          _buildRemoveListingButton(
                            context,
                            currentRooms,
                            cubit,
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          // ── MULTI-ROOM / BOARDING HOUSE UNIT MANAGER ───────────
                          // Single Property Cover Image + Black 'X Available' Badge
                          Container(
                            height: 210,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppColors.fieldFill,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.slate900.withValues(alpha: 0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  clipBehavior: Clip.antiAlias,
                                  child: ListingImagePlaceholder(
                                    seed: seed,
                                    photoUrl: currentRooms
                                            .map((r) => r.propertyCoverPhoto)
                                            .firstWhere(
                                              (u) => u != null && u.trim().isNotEmpty,
                                              orElse: () => null,
                                            ) ??
                                        currentProperty.effectiveBuildingCoverPhoto,
                                  ),
                                ),
                                // Top-Right Black Badge: "$availableCount Available" (no bullet, not bold, white text)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.scrim.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$availableCount Available',
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        color: AppColors.surface,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Property Detail Card (Same layout & style as Entire Property card, shadow only — no outline)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.slate900.withValues(alpha: 0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: AppColors.slate900.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name & Edit Button Row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.slate900,
                                          letterSpacing: -0.4,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    InkWell(
                                      onTap: () => _openEditInfo(
                                        context,
                                        currentProperty,
                                        currentRooms,
                                        cubit,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 11,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 13,
                                              color: AppColors.primary,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Edit',
                                              style: TextStyle(
                                                fontFamily: 'DM Sans',
                                                color: AppColors.primary,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Full Wrapping Address Row (no truncation)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 1.5),
                                      child: Icon(
                                        Icons.location_on_outlined,
                                        size: 14.5,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        currentProperty.address,
                                        softWrap: true,
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.slate500,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Rating & Reviews Redirect Row
                                InkWell(
                                  onTap: () => PropertyReviewsScreen.open(
                                    context,
                                    property: currentProperty,
                                    rooms: currentRooms,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 16.5,
                                          color: AppColors.matchMedium,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatPropertyRatingLabel(
                                            currentProperty,
                                            currentRooms,
                                          ),
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.slate900,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 16,
                                          color: AppColors.slate400,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

const SizedBox(height: 14),
                                const Divider(
                                  height: 1,
                                  thickness: 0.8,
                                  color: AppColors.fieldFill,
                                ),
                                const SizedBox(height: 14),

                                // Property Type on left, Room Listing count on right
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          _buildMultiRoomPropertyTypeSvg(size: 18),
                                          const SizedBox(width: 7),
                                          Flexible(
                                            child: Text(
                                              displayType,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.slate900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${currentRooms.length} ${currentRooms.length == 1 ? 'Room Listing' : 'Room Listings'}',
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Room Listings Card (Shadow only — no outline)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.slate900.withValues(alpha: 0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: AppColors.slate900.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Room Listings',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w800,
                                        color: context.appColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    if (currentProperty.isRoom)
                                      InkWell(
                                        onTap: () =>
                                            _addUnit(context, currentProperty),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 11,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.add_rounded,
                                                size: 13.5,
                                                color: AppColors.primary,
                                              ),
                                              SizedBox(width: 3.5),
                                              Text(
                                                'Add Room',
                                                style: TextStyle(
                                                  fontFamily: 'DM Sans',
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Tap a room to edit details or update status',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.slate500,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                for (var i = 0; i < currentRooms.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 10),
                                  _UnitRow(
                                    index: i + 1,
                                    room: currentRooms[i],
                                    onSelectStatus: (status) => _selectRoomStatus(
                                      context,
                                      currentRooms[i],
                                      status,
                                      cubit,
                                    ),
                                    onTap: () => _editRoom(
                                      context,
                                      currentRooms[i],
                                      cubit,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          _buildRemoveListingButton(
                            context,
                            currentRooms,
                            cubit,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// ENTIRE PROPERTY OVERVIEW COMPONENTS (READ-ONLY VIEW MODE)
// ─────────────────────────────────────────────────────────────────────────────

/// Full-width photo gallery carousel with large rounded cover,
/// top-right photo count badge, full-screen zoomable lightbox with remove option,
/// and horizontally scrollable thumbnails with direct add-photo upload.
class _EntirePropertyPhotoCarousel extends StatefulWidget {
  const _EntirePropertyPhotoCarousel({
    required this.property,
    required this.seed,
    required this.cubit,
  });

  final PropertyDoc property;
  final int seed;
  final LandlordHomeCubit cubit;

  @override
  State<_EntirePropertyPhotoCarousel> createState() =>
      _EntirePropertyPhotoCarouselState();
}

class _EntirePropertyPhotoCarouselState
    extends State<_EntirePropertyPhotoCarousel> {
  late final PageController _pageController;
  int _selectedPhotoIndex = 0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.destructive,
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(PickSource source) async {
    final photos = List<String>.from(widget.property.photos);
    final publicIds = List<String>.from(widget.property.photoPublicIds);
    while (publicIds.length < photos.length) {
      publicIds.add('');
    }

    if (photos.length >= CloudinaryConfig.maxPropertyPhotos) {
      _showError(
        'Maximum ${CloudinaryConfig.maxPropertyPhotos} photos allowed.',
      );
      return;
    }

    final repo = CloudinaryImageUploadRepository();
    try {
      final localPath = await repo.pick(ImageKind.propertyPhoto, source);
      if (localPath == null || !mounted) return;

      setState(() => _isUploading = true);
      final uploaded = await repo.upload(ImageKind.propertyPhoto, localPath);
      if (!mounted) return;

      final updatedPhotos = [...photos, uploaded.url];
      final updatedIds = [...publicIds, uploaded.publicId];

      await widget.cubit.updateProperty(widget.property.propertyId, {
        'photos': updatedPhotos,
        'photoPublicIds': updatedIds,
      });

      if (!mounted) return;
      setState(() {
        _selectedPhotoIndex = updatedPhotos.length - 1;
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo added successfully.'),
          backgroundColor: AppColors.slate900,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      _showError('Failed to upload photo: $e');
    }
  }

  void _showAddPhotoSheet() {
    if (_isUploading) return;
    if (widget.property.photos.length >= CloudinaryConfig.maxPropertyPhotos) {
      _showError(
        'Maximum ${CloudinaryConfig.maxPropertyPhotos} photos allowed.',
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Photo',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(bCtx).pop();
                  _pickAndUploadPhoto(PickSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(bCtx).pop();
                  _pickAndUploadPhoto(PickSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFullScreenGallery(int initialIndex) async {
    if (widget.property.photos.isEmpty) return;

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: AppColors.scrimStrong,
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _FullScreenPhotoGallery(
              initialPhotos: List<String>.from(widget.property.photos),
              initialPublicIds:
                  List<String>.from(widget.property.photoPublicIds),
              initialIndex: initialIndex,
              onRemovePhoto: (index, updatedPhotos, updatedIds) async {
                await widget.cubit.updateProperty(
                  widget.property.propertyId,
                  {
                    'photos': updatedPhotos,
                    'photoPublicIds': updatedIds,
                  },
                );
                if (mounted) {
                  setState(() {
                    if (_selectedPhotoIndex >= updatedPhotos.length) {
                      _selectedPhotoIndex =
                          (updatedPhotos.length - 1).clamp(0, 99);
                    }
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.property.photos;
    final photoCount = photos.length;
    final safeIndex = photoCount > 0
        ? _selectedPhotoIndex.clamp(0, photoCount - 1)
        : 0;
    final canAddMore = photoCount < CloudinaryConfig.maxPropertyPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Large Rounded Image (Swipeable PageView)
        Container(
          height: 210,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.fieldFill,
            boxShadow: [
              BoxShadow(
                color: AppColors.slate900.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: photoCount > 0
                    ? PageView.builder(
                        controller: _pageController,
                        itemCount: photoCount,
                        onPageChanged: (index) {
                          setState(() => _selectedPhotoIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final photoUrl = photos[index];
                          return GestureDetector(
                            onTap: () => _openFullScreenGallery(index),
                            child: Image.network(
                              photoUrl,
                              cacheWidth: 1280,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (_, _, _) =>
                                  ListingImagePlaceholder(
                                seed: widget.seed,
                                photoUrl: null,
                              ),
                            ),
                          );
                        },
                      )
                    : ListingImagePlaceholder(
                        seed: widget.seed,
                        photoUrl: null,
                      ),
              ),

              // Subtle outline border overlay on top so corners are razor-sharp
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.slate200.withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Right Photo Count Badge (transparent glass)
              if (photoCount > 0)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.5,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.scrim.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.surface.withValues(alpha: 0.35),
                            width: 0.6,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_outlined,
                              size: 10.5,
                              color: AppColors.surface,
                            ),
                            const SizedBox(width: 3.5),
                            Text(
                              photoCount > 1
                                  ? '${safeIndex + 1} / $photoCount'
                                  : '$photoCount',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                color: AppColors.surface,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Horizontal Thumbnails Row
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length + (canAddMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index < photos.length) {
                final isSelected = index == safeIndex;
                final thumbUrl = photos[index];

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPhotoIndex = index);
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            thumbUrl,
                            cacheWidth: 168,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.fieldFill,
                              child: const Icon(
                                Icons.broken_image,
                                size: 18,
                                color: AppColors.hint,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.slate200,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Direct Add Photo Button tile at the end
              return GestureDetector(
                onTap: _showAddPhotoSheet,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.slate200,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: _isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.add_rounded,
                            color: AppColors.slate500,
                            size: 20,
                          ),
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

class _FullScreenPhotoGallery extends StatefulWidget {
  const _FullScreenPhotoGallery({
    required this.initialPhotos,
    required this.initialPublicIds,
    required this.initialIndex,
    required this.onRemovePhoto,
  });

  final List<String> initialPhotos;
  final List<String> initialPublicIds;
  final int initialIndex;
  final Future<void> Function(
    int removedIndex,
    List<String> updatedPhotos,
    List<String> updatedPublicIds,
  ) onRemovePhoto;

  @override
  State<_FullScreenPhotoGallery> createState() =>
      _FullScreenPhotoGalleryState();
}

class _FullScreenPhotoGalleryState extends State<_FullScreenPhotoGallery> {
  late List<String> _photos;
  late List<String> _publicIds;
  late int _currentIndex;
  late PageController _pageController;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _photos = List<String>.from(widget.initialPhotos);
    _publicIds = List<String>.from(widget.initialPublicIds);
    while (_publicIds.length < _photos.length) {
      _publicIds.add('');
    }
    _currentIndex = widget.initialIndex.clamp(0, _photos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndRemoveCurrent() async {
    if (_isRemoving) return;
    if (_photos.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A listing must have at least one photo.'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove Photo?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        content: const Text(
          'Are you sure you want to remove this photo from the listing?',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRemoving = true);
    try {
      final removedIdx = _currentIndex;
      final nextPhotos = List<String>.from(_photos)..removeAt(removedIdx);
      final nextIds = List<String>.from(_publicIds);
      if (removedIdx < nextIds.length) {
        nextIds.removeAt(removedIdx);
      }

      await widget.onRemovePhoto(removedIdx, nextPhotos, nextIds);
      if (!mounted) return;

      setState(() {
        _photos = nextPhotos;
        _publicIds = nextIds;
        if (_currentIndex >= _photos.length) {
          _currentIndex = (_photos.length - 1).clamp(0, 99);
        }
        _isRemoving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo removed.'),
          backgroundColor: AppColors.slate900,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRemoving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove photo: $e'),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scrim.withValues(alpha: 0.94),
      body: SafeArea(
        child: Stack(
          children: [
            // Full-Screen Zoomable PageView
            PageView.builder(
              controller: _pageController,
              itemCount: _photos.length,
              onPageChanged: (idx) => setState(() => _currentIndex = idx),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      _photos[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.surface.withValues(alpha: 0.54),
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Top Bar: Counter + X Close Button
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${_photos.length}',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        color: AppColors.surface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.surface,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Bar: Remove Photo Action
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _isRemoving ? null : _confirmAndRemoveCurrent,
                  icon: _isRemoving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.surface,
                          ),
                        )
                      : const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(
                    _isRemoving ? 'Removing...' : 'Remove Photo',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main Property Card: combines property name, edit action, 70% width address,
/// bottom-right rent, and quick rental status selector with confirmation dialog.
class _EntirePropertyMainCard extends StatelessWidget {
  const _EntirePropertyMainCard({
    required this.property,
    required this.displayName,
    required this.displayType,
    required this.cubit,
    this.onEdit,
  });

  final PropertyDoc property;
  final String displayName;
  final String displayType;
  final LandlordHomeCubit cubit;
  final VoidCallback? onEdit;

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(_kThousandsRe, (m) => '${m[1]},');

  Future<void> _selectStatus(BuildContext context, String targetStatus) async {
    final currentStatus = property.vacancyStatus.isNotEmpty
        ? property.vacancyStatus
        : (property.isAvailable ? 'available' : 'booked');
    if (targetStatus == currentStatus) return;

    final targetLabel =
        targetStatus == 'available' ? 'Available' : 'Occupied';

    final explanation = targetStatus == 'available'
        ? 'Marking this property as Available will display it in tenant search results and allow compatible tenants to send inquiries.'
        : 'Marking this property as Occupied will hide it from public search results and prevent new tenant inquiries.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Change Status to $targetLabel?',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          explanation,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            color: AppColors.slate600,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  elevation: 0,
                  minimumSize: const Size(110, 42),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await cubit.setVacancy(property.propertyId, targetStatus);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rental status updated to $targetLabel.'),
            backgroundColor: AppColors.slate900,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = property.vacancyStatus.isNotEmpty
        ? property.vacancyStatus
        : (property.isAvailable ? 'available' : 'booked');
    final buildingName = (property.propertyName?.trim().isNotEmpty ?? false)
        ? property.propertyName!.trim()
        : (property.title.contains(' – ')
            ? property.title.split(' – ').first.trim()
            : '');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Heading: Room / Property Title & Edit Button Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          color: AppColors.primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Secondary Subheading: Parent Property Name (for room listings)
          if (property.isRoom &&
              buildingName.isNotEmpty &&
              buildingName != displayName) ...[
            const SizedBox(height: 4),
            Text(
              buildingName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.slate700,
                letterSpacing: -0.1,
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Tertiary Text: Full Wrapping Address Row with Theme Blue Pin
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1.5),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 14.5,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  property.address,
                  softWrap: true,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.slate500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Rating & Reviews Redirect Row
          InkWell(
            onTap: () => PropertyReviewsScreen.open(
              context,
              property: property,
            ),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 16.5,
                    color: AppColors.matchMedium,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatPropertyRatingLabel(property),
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.slate400,
                  ),
                ],
              ),
            ),
          ),

const SizedBox(height: 14),
          const Divider(height: 1, thickness: 0.8, color: AppColors.fieldFill),
          const SizedBox(height: 14),

          // Property Details Row (Building Type on left, Price on right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildPropertyTypeSvg(size: 18),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        displayType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.slate900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₱${_fmt(property.monthlyRent)}',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '/ month',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.8, color: AppColors.fieldFill),
          const SizedBox(height: 16),

          // Rental Status Row with Dropdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rental Status',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage availability',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusDropdown(context, status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context, String currentStatus) {
    final isAvailable = currentStatus == 'available';
    final label = isAvailable ? 'Available' : 'Occupied';
    final color = isAvailable ? AppColors.green600 : AppColors.slate600;

    return PopupMenuButton<String>(
      tooltip: 'Change Rental Status',
      onSelected: (targetStatus) => _selectStatus(context, targetStatus),
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.slate200, width: 1),
      ),
      color: AppColors.surface,
      elevation: 4,
      itemBuilder: (context) => [
        _buildPopupMenuItem(
          value: 'available',
          label: 'Available',
          dotColor: AppColors.green600,
          isSelected: isAvailable,
        ),
        _buildPopupMenuItem(
          value: 'booked',
          label: 'Occupied',
          dotColor: AppColors.slate600,
          isSelected: !isAvailable,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required String label,
    required Color dotColor,
    required bool isSelected,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.slate900,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check_rounded, size: 16, color: dotColor),
          ],
        ],
      ),
    );
  }

  Widget _buildPropertyTypeSvg({
    double size = 20,
    Color color = AppColors.slate900,
  }) {
    return SvgPicture.string(
      '''<svg xmlns="http://www.w3.org/2000/svg" width="$size" height="$size" viewBox="0 0 24 24" fill="none" stroke="#0F172A" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3 21l18 0" />
  <path d="M5 21v-14l8 -4v18" />
  <path d="M19 21v-10l-6 -4" />
  <path d="M9 9l0 .01" />
  <path d="M9 12l0 .01" />
  <path d="M9 15l0 .01" />
  <path d="M9 18l0 .01" />
</svg>''',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPANDABLE SECTION 1: RENT & CAPACITY
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandableRentSection extends StatefulWidget {
  const _ExpandableRentSection({
    required this.property,
    required this.cubit,
  });

  final PropertyDoc property;
  final LandlordHomeCubit cubit;

  @override
  State<_ExpandableRentSection> createState() => _ExpandableRentSectionState();
}

class _ExpandableRentSectionState extends State<_ExpandableRentSection> {
  bool _isExpanded = false;
  bool _isSaving = false;
  late final TextEditingController _rentCtrl;
  late final TextEditingController _maxOccupantsCtrl;

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(_kThousandsRe, (m) => '${m[1]},');

  @override
  void initState() {
    super.initState();
    _rentCtrl = TextEditingController(
      text: widget.property.monthlyRent > 0
          ? widget.property.monthlyRent.round().toString()
          : '',
    );
    _maxOccupantsCtrl = TextEditingController(
      text: widget.property.maxOccupants > 0
          ? widget.property.maxOccupants.round().toString()
          : '1',
    );
  }

  @override
  void didUpdateWidget(covariant _ExpandableRentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property.propertyId != widget.property.propertyId) {
      _rentCtrl.text = widget.property.monthlyRent > 0
          ? widget.property.monthlyRent.round().toString()
          : '';
      _maxOccupantsCtrl.text = widget.property.maxOccupants > 0
          ? widget.property.maxOccupants.round().toString()
          : '1';
    }
  }

  @override
  void dispose() {
    _rentCtrl.dispose();
    _maxOccupantsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final rent = int.tryParse(_rentCtrl.text.trim()) ?? 0;
    final maxOccupants = int.tryParse(_maxOccupantsCtrl.text.trim()) ?? 1;

    if (rent <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monthly rent must be greater than 0.'),
          backgroundColor: AppColors.red600,
        ),
      );
      return;
    }
    if (maxOccupants < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum occupants must be at least 1.'),
          backgroundColor: AppColors.red600,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.cubit.updateProperty(
        widget.property.propertyId,
        <String, dynamic>{
          'monthlyRent': rent,
          'maxOccupants': maxOccupants,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rent & capacity updated.'),
          backgroundColor: AppColors.slate900,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save rent & capacity.'),
          backgroundColor: AppColors.red600,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final occCount = p.maxOccupants.round();
    final summary =
        '₱${_fmt(p.monthlyRent)} / month  ·  Max $occCount ${occCount == 1 ? 'occupant' : 'occupants'}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.payments_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rent & Capacity',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: AppColors.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_isExpanded
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.fieldFill,
                        ),
                        const SizedBox(height: 16),
                        LabelledField(
                          label: 'Monthly rent (₱)',
                          child: AppTextField(
                            controller: _rentCtrl,
                            hintText: '3500',
                            prefixText: '₱ ',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        LabelledField(
                          label: 'Maximum number of occupants',
                          child: AppTextField(
                            controller: _maxOccupantsCtrl,
                            hintText: '1',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ExpandableSaveButton(
                          label: _isSaving
                              ? 'Saving...'
                              : 'Save Rent & Capacity',
                          onPressed: _isSaving ? null : _save,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPANDABLE SECTION 2: HOUSE RULES
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandableRulesSection extends StatefulWidget {
  const _ExpandableRulesSection({
    required this.property,
    required this.cubit,
  });

  final PropertyDoc property;
  final LandlordHomeCubit cubit;

  @override
  State<_ExpandableRulesSection> createState() =>
      _ExpandableRulesSectionState();
}

class _ExpandableRulesSectionState extends State<_ExpandableRulesSection> {
  bool _isExpanded = false;
  bool _isSaving = false;

  late final TextEditingController _depositCtrl;
  late final TextEditingController _advanceCtrl;
  late String _allowedGender;
  late bool _smokingAllowed;
  late bool _petsAllowed;
  late int? _curfewHours;

  static const List<int?> _curfewOptions = <int?>[null, 20, 21, 22, 23, 0];

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(_kThousandsRe, (m) => '${m[1]},');

  static String _formatCurfewHour(int hour) {
    if (hour == 0) return '12:00 AM (midnight)';
    if (hour == 12) return '12:00 PM';
    if (hour > 12) return '${hour - 12}:00 PM';
    return '$hour:00 AM';
  }

  @override
  void initState() {
    super.initState();
    _depositCtrl = TextEditingController(
      text: widget.property.depositAmount > 0
          ? widget.property.depositAmount.round().toString()
          : '0',
    );
    _advanceCtrl = TextEditingController(
      text: widget.property.advanceMonths > 0
          ? widget.property.advanceMonths.round().toString()
          : '1',
    );
    _syncFromProperty(widget.property);
  }

  void _syncFromProperty(PropertyDoc p) {
    _allowedGender = <String>['Mixed / Any', 'Male only', 'Female only']
            .contains(p.allowedGender)
        ? p.allowedGender
        : 'Mixed / Any';
    _smokingAllowed = p.smokingAllowed;
    _petsAllowed = p.petsAllowed;
    final rawCurfew = p.curfewHours?.round();
    if (rawCurfew == null) {
      _curfewHours = null;
    } else if (_curfewOptions.contains(rawCurfew)) {
      _curfewHours = rawCurfew;
    } else {
      _curfewHours = 22;
    }
  }

  @override
  void didUpdateWidget(covariant _ExpandableRulesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property.propertyId != widget.property.propertyId) {
      _depositCtrl.text = widget.property.depositAmount > 0
          ? widget.property.depositAmount.round().toString()
          : '0';
      _advanceCtrl.text = widget.property.advanceMonths > 0
          ? widget.property.advanceMonths.round().toString()
          : '1';
      _syncFromProperty(widget.property);
    }
  }

  @override
  void dispose() {
    _depositCtrl.dispose();
    _advanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final deposit = int.tryParse(_depositCtrl.text.trim()) ?? 0;
    final advanceMonths = int.tryParse(_advanceCtrl.text.trim()) ?? 1;

    if (deposit < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security deposit cannot be negative.'),
          backgroundColor: AppColors.red600,
        ),
      );
      return;
    }
    if (advanceMonths < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Advance rent cannot be negative.'),
          backgroundColor: AppColors.red600,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.cubit.updateProperty(
        widget.property.propertyId,
        <String, dynamic>{
          'depositAmount': deposit,
          'advanceMonths': advanceMonths,
          'allowedGender': _allowedGender,
          'smokingAllowed': _smokingAllowed,
          'petsAllowed': _petsAllowed,
          'curfewHours': _curfewHours ?? FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('House rules updated.'),
          backgroundColor: AppColors.slate900,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save house rules.'),
          backgroundColor: AppColors.red600,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final curfewLabel = p.curfewHours == null
        ? 'No curfew'
        : 'Curfew ${_formatCurfewHour(p.curfewHours!.round())}';
    final summary =
        'Deposit ₱${_fmt(p.depositAmount)}  ·  ${p.advanceMonths.round()} mo advance  ·  $curfewLabel';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.fact_check_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'House Rules',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: AppColors.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_isExpanded
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.fieldFill,
                        ),
                        const SizedBox(height: 16),
                        LabelledField(
                          label: 'Security deposit (₱)',
                          child: AppTextField(
                            controller: _depositCtrl,
                            hintText: '3500',
                            prefixText: '₱ ',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        LabelledField(
                          label: 'Advance rent (months)',
                          child: AppTextField(
                            controller: _advanceCtrl,
                            hintText: '1',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        LabelledField(
                          label: 'Who can rent?',
                          child: ListingDropdown<String>(
                            value: _allowedGender,
                            hint: 'Select...',
                            items: const [
                              DropdownMenuItem(
                                value: 'Mixed / Any',
                                child: Text('Anyone'),
                              ),
                              DropdownMenuItem(
                                value: 'Male only',
                                child: Text('Male only'),
                              ),
                              DropdownMenuItem(
                                value: 'Female only',
                                child: Text('Female only'),
                              ),
                            ],
                            onChanged: (v) => setState(
                              () => _allowedGender = v ?? _allowedGender,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ListingToggleRow(
                          label: 'Smoking allowed',
                          value: _smokingAllowed,
                          onChanged: (v) =>
                              setState(() => _smokingAllowed = v),
                        ),
                        const SizedBox(height: 8),
                        ListingToggleRow(
                          label: 'Pets allowed',
                          value: _petsAllowed,
                          onChanged: (v) => setState(() => _petsAllowed = v),
                        ),
                        const SizedBox(height: 14),
                        LabelledField(
                          label: 'Curfew',
                          child: ListingDropdown<int?>(
                            value: _curfewHours,
                            hint: 'Select curfew',
                            items: [
                              for (final h in _curfewOptions)
                                DropdownMenuItem<int?>(
                                  value: h,
                                  child: Text(
                                    h == null
                                        ? 'No curfew'
                                        : _formatCurfewHour(h),
                                  ),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => _curfewHours = v),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ExpandableSaveButton(
                          label: _isSaving ? 'Saving...' : 'Save House Rules',
                          onPressed: _isSaving ? null : _save,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPANDABLE SECTION 3: AMENITIES
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandableAmenitiesSection extends StatefulWidget {
  const _ExpandableAmenitiesSection({
    required this.property,
    required this.cubit,
  });

  final PropertyDoc property;
  final LandlordHomeCubit cubit;

  @override
  State<_ExpandableAmenitiesSection> createState() =>
      _ExpandableAmenitiesSectionState();
}

class _ExpandableAmenitiesSectionState
    extends State<_ExpandableAmenitiesSection> {
  bool _isExpanded = false;
  bool _isSaving = false;
  late Set<String> _amenities;

  @override
  void initState() {
    super.initState();
    _amenities = Set<String>.from(widget.property.amenityList);
  }

  @override
  void didUpdateWidget(covariant _ExpandableAmenitiesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property.propertyId != widget.property.propertyId) {
      _amenities = Set<String>.from(widget.property.amenityList);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final sortedAmenities = _amenities.toList()..sort();
      await widget.cubit.updateProperty(
        widget.property.propertyId,
        <String, dynamic>{
          'amenityList': sortedAmenities,
          'amenityScore': sortedAmenities.length,
          'hasWifi': _amenities.contains('WiFi'),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amenities updated.'),
          backgroundColor: AppColors.slate900,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save amenities.'),
          backgroundColor: AppColors.red600,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.property.amenityList.length;
    final summary = count == 0
        ? 'No amenities selected'
        : '$count of 14 amenities selected';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.grid_view_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Amenities',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: AppColors.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_isExpanded
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.fieldFill,
                        ),
                        const SizedBox(height: 14),
                        for (final (group, items) in kAmenityGroups) ...[
                          Text(
                            group.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: context.appColors.textSecondary,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final a in items)
                                AmenityChip(
                                  label: a,
                                  selected: _amenities.contains(a),
                                  onTap: () => setState(() {
                                    if (_amenities.contains(a)) {
                                      _amenities.remove(a);
                                    } else {
                                      _amenities.add(a);
                                    }
                                  }),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                        Text(
                          '${_amenities.length} of 14 selected',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ExpandableSaveButton(
                          label: _isSaving ? 'Saving...' : 'Save Amenities',
                          onPressed: _isSaving ? null : _save,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableSaveButton extends StatelessWidget {
  const _ExpandableSaveButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// MULTI-ROOM UNIT ROW
// ─────────────────────────────────────────────────────────────────────────────

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.index,
    required this.room,
    required this.onSelectStatus,
    required this.onTap,
  });

  final int index;
  final PropertyDoc room;
  final ValueChanged<String> onSelectStatus;
  final VoidCallback onTap;

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(_kThousandsRe, (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final currentStatus = room.vacancyStatus.isNotEmpty
        ? room.vacancyStatus
        : (room.isAvailable ? 'available' : 'booked');
    final roomTitle = room.roomName?.trim().isNotEmpty == true
        ? room.roomName!.trim()
        : (room.isRoom ? 'Room $index' : 'Entire Place');
    final seed = room.propertyId.hashCode % 5 + 1;
    final roomImageUrl = room.photos.isNotEmpty
        ? room.photos.first
        : room.effectiveBuildingCoverPhoto;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.slate900.withValues(alpha: 0.08),
              blurRadius: 14,
              spreadRadius: 0.5,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.slate900.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Room First Photo Thumbnail (replaces number card)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.slate200,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.slate900.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ListingImagePlaceholder(
                  seed: seed,
                  photoUrl: roomImageUrl,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roomTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '₱${_fmt(room.monthlyRent)}',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const TextSpan(
                          text: ' / month',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildRoomStatusDropdown(context, currentStatus),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.slate400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomStatusDropdown(BuildContext context, String currentStatus) {
    final isAvailable = currentStatus == 'available';
    final label = isAvailable ? 'Available' : 'Occupied';
    final color = isAvailable ? AppColors.green600 : AppColors.slate600;

    return PopupMenuButton<String>(
      tooltip: 'Change Room Status',
      onSelected: onSelectStatus,
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.slate200, width: 1),
      ),
      color: AppColors.surface,
      elevation: 4,
      itemBuilder: (context) => [
        _buildPopupMenuItem(
          value: 'available',
          label: 'Available',
          dotColor: AppColors.green600,
          isSelected: isAvailable,
        ),
        _buildPopupMenuItem(
          value: 'booked',
          label: 'Occupied',
          dotColor: AppColors.slate600,
          isSelected: !isAvailable,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.slate900.withValues(alpha: 0.09),
              blurRadius: 10,
              spreadRadius: 0.5,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: AppColors.slate900.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required String label,
    required Color dotColor,
    required bool isSelected,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.slate900,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check_rounded, size: 16, color: dotColor),
          ],
        ],
      ),
    );
  }
}

String _formatPropertyRatingLabel(PropertyDoc property, [List<PropertyDoc> rooms = const []]) {
  num? avg = property.effectiveAvgRating ?? property.avgRating;
  num count = property.totalRatings ?? 0;
  if (rooms.isNotEmpty) {
    num sum = 0;
    num total = 0;
    for (final r in rooms) {
      final rAvg = r.effectiveAvgRating ?? r.avgRating;
      final rCount = r.totalRatings ?? 0;
      if (rAvg != null && rCount > 0) {
        sum += (r.ratingSum ?? (rAvg * rCount));
        total += rCount;
      }
    }
    if (total > 0) {
      avg = sum / total;
      count = total;
    }
  }
  if (avg != null && count > 0) {
    return '${avg.toStringAsFixed(1)} ($count)';
  }
  return '0';
}
