import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/models/models.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../activity/data/repositories/notification_repository_impl.dart';
import '../../auth/presentation/current_uid.dart';
import '../../inquiry/data/repositories/inquiry_repository_impl.dart';
import '../../inquiry/domain/services/inquiry_service.dart';
import '../../owner/data/repositories/find_tenants_repository_impl.dart';
import '../../owner/model/compatible_tenant.dart';
import '../../owner/view/edit_property_screen.dart';
import '../../owner_onboarding/view/create_listing_wizard_screen.dart';
import '../cubit/landlord_home_cubit.dart';
import '../view/tenant_detail_screen.dart';
import '../widgets/edit_property_sheet.dart';
import 'edit_entire_property_screen.dart';

/// Screen displayed when clicking an owner property card.
///
/// Supports two distinct modes:
/// 1. Entire Property: Read-only overview with live status toggle (with confirmation),
///    amenities, rules/specs, compatible tenants list with invitation actions,
///    and a prominent Edit button navigating to [EditEntirePropertyScreen].
/// 2. Multi-Unit Property: Room unit manager with per-unit occupancy toggles.
class PropertyManagerScreen extends StatefulWidget {
  const PropertyManagerScreen({
    required this.initialProperty,
    required this.initialRooms,
    super.key,
  });

  final PropertyDoc initialProperty;
  final List<PropertyDoc> initialRooms;

  @override
  State<PropertyManagerScreen> createState() => _PropertyManagerScreenState();
}

class _PropertyManagerScreenState extends State<PropertyManagerScreen> {
  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Future<void> _toggleSingleUnit(
    BuildContext context,
    PropertyDoc room,
    LandlordHomeCubit cubit,
  ) async {
    final newStatus = room.isAvailable ? 'booked' : 'available';
    await cubit.setVacancy(room.propertyId, newStatus);
  }

  Future<void> _toggleAllUnits(
    BuildContext context,
    List<PropertyDoc> rooms,
    LandlordHomeCubit cubit,
  ) async {
    final anyAvailable = rooms.any((r) => r.isAvailable);
    final targetStatus = anyAvailable ? 'booked' : 'available';
    for (final r in rooms) {
      await cubit.setVacancy(r.propertyId, targetStatus);
    }
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

    showEditPropertySheet(
      context: context,
      initialName: buildingName,
      initialType: buildingType,
      initialAddress: property.address,
      initialLocation: location,
      onSave: ({
        required String name,
        required String type,
        required String address,
        required LatLng location,
      }) async {
        final updates = <String, dynamic>{
          'propertyName': name,
          'propertyType': type,
          'address': address,
          'location': GeoPoint(location.latitude, location.longitude),
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
        builder: (_) => EditPropertyScreen(
          property: room,
          onSave: (fields) => cubit.updateProperty(room.propertyId, fields),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LandlordHomeCubit>();

    return BlocBuilder<LandlordHomeCubit, LandlordHomeState>(
      builder: (context, state) {
        final propId = widget.initialProperty.propertyId;
        final parentId = widget.initialProperty.parentPropertyId;

        final liveRooms = state.properties.where((p) {
          if (parentId != null && parentId.isNotEmpty) {
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
        final displayName = (currentProperty.propertyName?.trim().isNotEmpty ?? false)
            ? currentProperty.propertyName!.trim()
            : currentProperty.title;
        final displayType = (currentProperty.propertyType?.trim().isNotEmpty ?? false)
            ? currentProperty.propertyType!.trim()
            : (currentProperty.isRoom ? 'Boarding House' : 'Apartment');
        final int seed = currentProperty.propertyId.hashCode % 5 + 1;
        final isEntirePlace = !currentProperty.isRoom;

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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
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
              'Property Management',
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

                        if (isEntirePlace) ...[
                          // ── READ-ONLY OVERVIEW FOR ENTIRE PROPERTY ───────────
                          _EntirePropertyPhotoCarousel(
                            property: currentProperty,
                            seed: seed,
                            onAddPhoto: () => _openEditEntireProperty(
                              context,
                              currentProperty,
                              cubit,
                              initialTabIndex: 1,
                            ),
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

                          _EntirePropertyCompatibleTenantsSection(
                            property: currentProperty,
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          // ── MULTI-ROOM / BOARDING HOUSE UNIT MANAGER ───────────
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                  child: ListingImagePlaceholder(
                                    seed: seed,
                                    photoUrl: currentProperty.photos.isNotEmpty
                                        ? currentProperty.photos.first
                                        : null,
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7.5,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: availableCount > 0
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF0F172A).withValues(alpha: 0.82),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: availableCount > 0
                                            ? const Color(0xFF34D399).withValues(alpha: 0.4)
                                            : Colors.white.withValues(alpha: 0.16),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 4.5,
                                          height: 4.5,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: availableCount > 0
                                                ? const Color(0xFFA7F3D0)
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          availableCount > 0
                                              ? '$availableCount Available'
                                              : 'No Vacancy',
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 10,
                                  right: 10,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7.5,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 12,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 3.5),
                                          Flexible(
                                            child: Text(
                                              currentProperty.address,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Property Info Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.025),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Text(
                                        displayType,
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₱${_fmt(currentProperty.monthlyRent)}/mo',
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const Text(
                                          'Rental Rate',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: context.appColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentProperty.address,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF64748B),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Room Units & Real-time Slots Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.025),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentProperty.isRoom
                                                ? 'Room Units & Real-time Slots'
                                                : 'Listing Space',
                                            style: TextStyle(
                                              fontFamily: 'DM Sans',
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: context.appColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Tap room status button to toggle occupancy',
                                            style: TextStyle(
                                              fontFamily: 'DM Sans',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (currentProperty.isRoom)
                                      GestureDetector(
                                        onTap: () =>
                                            _addUnit(context, currentProperty),
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: AppColors.primary.withValues(alpha: 0.25),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.add_rounded,
                                                size: 14,
                                                color: AppColors.primary,
                                              ),
                                              SizedBox(width: 3),
                                              Text(
                                                'Add Unit',
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
                                const SizedBox(height: AppSpacing.md),

                                for (var i = 0; i < currentRooms.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 10),
                                  _UnitRow(
                                    index: i + 1,
                                    room: currentRooms[i],
                                    onToggleStatus: () => _toggleSingleUnit(
                                      context,
                                      currentRooms[i],
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
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── BOTTOM ACTION BUTTON (MULTI-UNIT ONLY) ───────────────────
                if (!isEntirePlace)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _toggleAllUnits(
                              context,
                              currentRooms,
                              cubit,
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sync_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Toggle All Units',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _openEditInfo(
                              context,
                              currentProperty,
                              currentRooms,
                              cubit,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Edit Info',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
/// top-right photo count badge, and horizontally scrollable thumbnails with add button.
class _EntirePropertyPhotoCarousel extends StatefulWidget {
  const _EntirePropertyPhotoCarousel({
    required this.property,
    required this.seed,
    this.onAddPhoto,
  });

  final PropertyDoc property;
  final int seed;
  final VoidCallback? onAddPhoto;

  @override
  State<_EntirePropertyPhotoCarousel> createState() =>
      _EntirePropertyPhotoCarouselState();
}

class _EntirePropertyPhotoCarouselState
    extends State<_EntirePropertyPhotoCarousel> {
  int _selectedPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.property.photos;
    final photoCount = photos.length;
    final currentPhoto = photos.isNotEmpty && _selectedPhotoIndex < photos.length
        ? photos[_selectedPhotoIndex]
        : (photos.isNotEmpty ? photos.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Large Rounded Image
        Container(
          height: 210,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFFF1F5F9),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: currentPhoto != null
                    ? Image.network(
                        currentPhoto,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, _, _) => ListingImagePlaceholder(
                          seed: widget.seed,
                          photoUrl: null,
                        ),
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
                        color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),

              // Top Right Photo Count Badge
              if (photoCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          photoCount > 1
                              ? '${_selectedPhotoIndex + 1} / $photoCount'
                              : '$photoCount',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
            itemCount: photos.length + 1, // photos + add photo button
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index < photos.length) {
                final isSelected = index == _selectedPhotoIndex;
                final thumbUrl = photos[index];

                return GestureDetector(
                  onTap: () => setState(() => _selectedPhotoIndex = index),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: Image.network(
                            thumbUrl,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, _, _) => Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.broken_image, size: 18, color: Colors.grey),
                            ),
                          ),
                        ),
                        // Border overlay drawn ON TOP so outline corners never glitch
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFFE2E8F0),
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

              // Add Photo Button tile at the end
              return GestureDetector(
                onTap: widget.onAddPhoto,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Color(0xFF64748B),
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
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Future<void> _selectStatus(BuildContext context, String targetStatus) async {
    final currentStatus = property.vacancyStatus.isNotEmpty
        ? property.vacancyStatus
        : (property.isAvailable ? 'available' : 'booked');
    if (targetStatus == currentStatus) return;

    final targetLabel = switch (targetStatus) {
      'available' => 'Available',
      'pending' => 'Pending',
      _ => 'Occupied',
    };

    final explanation = switch (targetStatus) {
      'available' =>
        'Marking this property as Available will display it in tenant search results and allow compatible tenants to send inquiries.',
      'pending' =>
        'Marking this property as Pending indicates it is temporarily reserved or awaiting confirmation.',
      _ =>
        'Marking this property as Occupied will hide it from public search results and prevent new tenant inquiries.',
    };

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
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
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
    );

    if (confirmed == true && context.mounted) {
      try {
        await cubit.setVacancy(property.propertyId, targetStatus);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rental status updated to $targetLabel.'),
            backgroundColor: const Color(0xFF0F172A),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 3.5),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Address Row with location pin icon (60% width)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 5),
              Expanded(
                flex: 6,
                child: Text(
                  property.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const Expanded(flex: 4, child: SizedBox()),
            ],
          ),

          const SizedBox(height: 24),

          // Property Details Row (Building Type on left, Price on right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildPropertyTypeSvg(size: 20),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        displayType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
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
                      fontSize: 22,
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
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
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
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage availability',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
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
    final label = switch (currentStatus) {
      'available' => 'Available',
      'pending' => 'Pending',
      _ => 'Occupied',
    };

    final color = switch (currentStatus) {
      'available' => const Color(0xFF16A34A),
      'pending' => const Color(0xFFD97706),
      _ => const Color(0xFF475569),
    };

    return PopupMenuButton<String>(
      tooltip: 'Change Rental Status',
      onSelected: (targetStatus) => _selectStatus(context, targetStatus),
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      color: Colors.white,
      elevation: 4,
      itemBuilder: (context) => [
        _buildPopupMenuItem(
          value: 'available',
          label: 'Available',
          dotColor: const Color(0xFF16A34A),
          isSelected: currentStatus == 'available',
        ),
        _buildPopupMenuItem(
          value: 'pending',
          label: 'Pending',
          dotColor: const Color(0xFFD97706),
          isSelected: currentStatus == 'pending',
        ),
        _buildPopupMenuItem(
          value: 'booked',
          label: 'Occupied',
          dotColor: const Color(0xFF475569),
          isSelected: currentStatus == 'booked',
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF0F172A),
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
              color: const Color(0xFF0F172A),
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
    Color color = const Color(0xFF0F172A),
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

/// Compatible Tenants section: loads actual matches from Firestore,
/// provides an individual Invite action, and a "Notify All" action.
class _EntirePropertyCompatibleTenantsSection extends StatefulWidget {
  const _EntirePropertyCompatibleTenantsSection({required this.property});

  final PropertyDoc property;

  @override
  State<_EntirePropertyCompatibleTenantsSection> createState() =>
      _EntirePropertyCompatibleTenantsSectionState();
}

class _EntirePropertyCompatibleTenantsSectionState
    extends State<_EntirePropertyCompatibleTenantsSection> {
  List<CompatibleTenant>? _tenants;
  bool _loading = true;
  String? _error;
  bool _isNotifyingAll = false;
  final Set<String> _notifiedTenantIds = {};

  @override
  void initState() {
    super.initState();
    _fetchCompatibleTenants();
  }

  @override
  void didUpdateWidget(covariant _EntirePropertyCompatibleTenantsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property.propertyId != widget.property.propertyId) {
      _fetchCompatibleTenants();
    }
  }

  Future<void> _fetchCompatibleTenants() async {
    final ownerId = currentUidOrNull(context);
    if (ownerId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = FindTenantsRepositoryImpl();
      final list = await repo.fetchCompatibleTenants(
        ownerId: ownerId,
        propertyId: widget.property.propertyId,
      );
      if (mounted) {
        setState(() {
          _tenants = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load compatible tenants.';
        });
      }
    }
  }

  Future<void> _notifyAll(BuildContext context) async {
    final tenants = _tenants ?? [];
    if (tenants.isEmpty) return;

    final ownerId = currentUidOrNull(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Notify All Compatible Tenants?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Send availability invitations for "${widget.property.title}" to ${tenants.length} eligible tenant(s)?',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text(
              'Notify All',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isNotifyingAll = true);
    int sentCount = 0;

    if (ownerId != null) {
      final service = InquiryService(
        repository: InquiryRepositoryImpl(),
        notifications: NotificationRepositoryImpl(),
      );

      for (final t in tenants) {
        try {
          await service.sendInvite(ownerId: ownerId, matchId: t.matchId);
          sentCount++;
          _notifiedTenantIds.add(t.tenantId);
        } catch (_) {
          // Swallow duplicate invitations or permission refusals
        }
      }
    }

    if (mounted) {
      setState(() => _isNotifyingAll = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            sentCount > 0
                ? 'Invitations sent to $sentCount tenant(s).'
                : 'All eligible compatible tenants have already been invited.',
          ),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
    }
  }

  Future<void> _notifySingle(BuildContext context, CompatibleTenant tenant) async {
    final ownerId = currentUidOrNull(context);
    if (ownerId == null) return;
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Notify ${tenant.name}?',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Send an availability invitation for "${widget.property.title}" to ${tenant.name}?',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text(
              'Notify',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final service = InquiryService(
        repository: InquiryRepositoryImpl(),
        notifications: NotificationRepositoryImpl(),
      );
      await service.sendInvite(ownerId: ownerId, matchId: tenant.matchId);
      if (mounted) {
        setState(() {
          _notifiedTenantIds.add(tenant.tenantId);
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Invitation sent to ${tenant.name}.'),
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Unable to send invitation at this time.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = widget.property.isAvailable &&
        widget.property.vacancyStatus != 'booked' &&
        widget.property.vacancyStatus != 'pending';
    final tenants = _tenants ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Compatible Tenants',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${tenants.length} matches',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isAvailable
                ? 'People who match your property requirements'
                : 'Availability notifications are paused while property is Pending or Occupied.',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _fetchCompatibleTenants,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          else if (tenants.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 26,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No compatible tenants yet',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tenants whose preferences match this listing will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < tenants.length; i++) ...[
                  _CompatibleTenantItem(
                    tenant: tenants[i],
                    property: widget.property,
                    isPropertyAvailable: isAvailable,
                    isNotified: _notifiedTenantIds.contains(tenants[i].tenantId),
                    avatarIndex: i,
                    onNotify: () => _notifySingle(context, tenants[i]),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          if (isAvailable && tenants.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                onPressed: _isNotifyingAll ? null : () => _notifyAll(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  foregroundColor: AppColors.primary,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isNotifyingAll) ...[
                      const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 7),
                    ] else ...[
                      const Icon(
                        Icons.notifications_active_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 7),
                    ],
                    Text(
                      _isNotifyingAll
                          ? 'Sending Invitations...'
                          : 'Notify All Compatible Tenants',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompatibleTenantItem extends StatelessWidget {
  const _CompatibleTenantItem({
    required this.tenant,
    required this.property,
    required this.isPropertyAvailable,
    required this.isNotified,
    required this.onNotify,
    this.avatarIndex = 0,
  });

  final CompatibleTenant tenant;
  final PropertyDoc property;
  final bool isPropertyAvailable;
  final bool isNotified;
  final VoidCallback? onNotify;
  final int avatarIndex;

  static const _avatarBgs = [
    Color(0xFFE0F2FE), // Sky
    Color(0xFFF3E8FF), // Purple
    Color(0xFFFCE7F3), // Pink
    Color(0xFFFEF3C7), // Amber
    Color(0xFFDCFCE7), // Emerald
  ];
  static const _avatarFgs = [
    AppColors.primary,
    Color(0xFF7E22CE),
    Color(0xFFBE185D),
    Color(0xFFB45309),
    Color(0xFF15803D),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = _avatarBgs[avatarIndex % _avatarBgs.length];
    final fg = _avatarFgs[avatarIndex % _avatarFgs.length];

    final details = [
      if (tenant.occupation?.isNotEmpty ?? false) tenant.occupation!,
      if (tenant.school?.isNotEmpty ?? false) tenant.school!,
      if (tenant.gender.isNotEmpty) tenant.gender,
      '₱${tenant.maxBudget}/mo budget',
    ].join(' · ');

    final matchPercentage = (tenant.bScore > 0 && tenant.bScore <= 1.0)
        ? (tenant.bScore * 100).toInt()
        : (tenant.bScore > 1 ? tenant.bScore.toInt() : 96);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TenantDetailScreen(tenant: tenant),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: bg,
              child: Text(
                tenant.initials.isNotEmpty ? tenant.initials : 'T',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 1.5),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                  const SizedBox(height: 2.5),
                  Text(
                    '$matchPercentage% compatible',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isPropertyAvailable) ...[
              if (isNotified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Notified',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: onNotify,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Notify',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ],
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
    required this.onToggleStatus,
    required this.onTap,
  });

  final int index;
  final PropertyDoc room;
  final VoidCallback onToggleStatus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAvailable = room.isAvailable;
    final isPending = room.vacancyStatus == 'pending';
    final roomTitle = room.roomName?.trim().isNotEmpty == true
        ? room.roomName!.trim()
        : (room.isRoom ? 'Room $index' : 'Entire Place');

    final statusLabel = isAvailable
        ? 'Available'
        : (isPending ? 'Pending' : 'Occupied');
    final statusColor = isAvailable
        ? const Color(0xFF10B981)
        : (isPending ? const Color(0xFFF59E0B) : const Color(0xFF64748B));
    final statusBg = isAvailable
        ? const Color(0xFFECFDF5)
        : (isPending ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9));
    final statusBorder = isAvailable
        ? const Color(0xFFA7F3D0)
        : (isPending ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Text(
                '$index',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roomTitle,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAvailable ? 'Occupant: Vacant' : 'Occupant: Occupied',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggleStatus,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
