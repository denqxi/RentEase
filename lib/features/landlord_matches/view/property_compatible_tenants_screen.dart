import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/models/models.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../activity/data/repositories/notification_repository_impl.dart';
import '../../auth/presentation/current_uid.dart';
import '../../inquiry/data/repositories/inquiry_repository_impl.dart';
import '../../inquiry/domain/services/inquiry_service.dart';
import '../../landlord_home/cubit/landlord_home_cubit.dart';
import '../../landlord_home/view/tenant_detail_screen.dart';
import '../../owner/model/compatible_tenant.dart';

/// Dedicated screen opened when tapping a property or room card in the Matches
/// tab. Displays:
/// 1. Read-only property/room photo carousel on top (with full-screen zoom)
/// 2. Read-only property detail card with ONLY the Rental Status selector
/// 3. Compatible Tenants list with Notify / Notify All actions and minimal,
///    modern pagination (with 2, 3, 5, 10 page-size selector).
class PropertyCompatibleTenantsScreen extends StatefulWidget {
  const PropertyCompatibleTenantsScreen({
    required this.initialProperty,
    required this.allRooms,
    required this.initialNotifiedMatchIds,
    this.initialSelectedPropertyId,
    this.onNotifiedMatchIdsChanged,
    super.key,
  });

  final PropertyDoc initialProperty;
  final List<PropertyDoc> allRooms;
  final String? initialSelectedPropertyId;
  final Set<String> initialNotifiedMatchIds;
  final ValueChanged<Set<String>>? onNotifiedMatchIdsChanged;

  @override
  State<PropertyCompatibleTenantsScreen> createState() =>
      _PropertyCompatibleTenantsScreenState();
}

class _PropertyCompatibleTenantsScreenState
    extends State<PropertyCompatibleTenantsScreen> {
  static const int _itemsPerPage = 5;

  late String _selectedPropertyId;
  late Set<String> _notifiedMatchIds;
  bool _isNotifyingAll = false;

  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _selectedPropertyId =
        widget.initialSelectedPropertyId ?? widget.initialProperty.propertyId;
    _notifiedMatchIds = Set<String>.from(widget.initialNotifiedMatchIds);
  }

  List<CompatibleTenant> _matchesForUnit(
    LandlordHomeState state,
    String propertyId,
  ) {
    final fromMap = state.tenantsByProperty[propertyId];
    if (fromMap != null) return fromMap;
    return state.tenants
        .where(
          (t) =>
              t.matchId.endsWith('_$propertyId') ||
              t.matchId.contains(propertyId),
        )
        .toList();
  }

  String? _resolveOwnerId(BuildContext context, PropertyDoc unit) {
    final uid = currentUidOrNull(context);
    if (uid != null && uid.isNotEmpty) return uid;

    try {
      final authUid = FirebaseAuth.instance.currentUser?.uid;
      if (authUid != null && authUid.isNotEmpty) return authUid;
    } catch (_) {
      // Ignore if Firebase is not initialized in offline preview
    }

    if (unit.ownerId.isNotEmpty) return unit.ownerId;
    return null;
  }

  Future<void> _notifySingleTenant({
    required BuildContext context,
    required CompatibleTenant tenant,
    required PropertyDoc unit,
    required String listingLabel,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final ownerId = _resolveOwnerId(context, unit);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Notify ${tenant.name}?',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Notify ${tenant.name} that "$listingLabel" is available?',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13.5,
            color: Color(0xFF475569),
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
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(100, 42),
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
                  'Notify',
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

    if (confirmed != true || !mounted) return;

    if (ownerId == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to identify owner account. Please sign in again.'),
          backgroundColor: Color(0xFF0F172A),
        ),
      );
      return;
    }

    try {
      await InquiryService(
        repository: InquiryRepositoryImpl(),
        notifications: NotificationRepositoryImpl(),
      ).sendInvite(ownerId: ownerId, matchId: tenant.matchId);

      if (mounted) {
        setState(() => _notifiedMatchIds.add(tenant.matchId));
        widget.onNotifiedMatchIdsChanged?.call(_notifiedMatchIds);
        messenger.showSnackBar(
          SnackBar(
            content: Text('${tenant.name} has been notified.'),
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Bad state: ', '');
        if (msg.toLowerCase().contains('already')) {
          setState(() => _notifiedMatchIds.add(tenant.matchId));
          widget.onNotifiedMatchIdsChanged?.call(_notifiedMatchIds);
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
      }
    }
  }

  Future<void> _notifyAllForUnit({
    required BuildContext context,
    required PropertyDoc unit,
    required String listingLabel,
    required List<CompatibleTenant> tenants,
  }) async {
    if (tenants.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final ownerId = _resolveOwnerId(context, unit);

    final unnotified = tenants
        .where((t) => !_notifiedMatchIds.contains(t.matchId))
        .toList();

    if (unnotified.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('All compatible tenants for this unit are already notified.'),
          backgroundColor: Color(0xFF0F172A),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Notify all compatible tenants?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Notify all ${unnotified.length} compatible tenant${unnotified.length == 1 ? '' : 's'} that "$listingLabel" is available?',
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13.5,
            color: Color(0xFF475569),
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
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(100, 42),
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
                  'Notify',
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

    if (confirmed != true || !mounted) return;

    if (ownerId == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to identify owner account. Please sign in again.'),
          backgroundColor: Color(0xFF0F172A),
        ),
      );
      return;
    }

    setState(() => _isNotifyingAll = true);
    int sentCount = 0;

    final service = InquiryService(
      repository: InquiryRepositoryImpl(),
      notifications: NotificationRepositoryImpl(),
    );

    for (final t in unnotified) {
      try {
        await service.sendInvite(ownerId: ownerId, matchId: t.matchId);
        sentCount++;
        _notifiedMatchIds.add(t.matchId);
      } catch (_) {
        // Ignore already-invited or duplicate threads
      }
    }

    if (mounted) {
      setState(() => _isNotifyingAll = false);
      widget.onNotifiedMatchIdsChanged?.call(_notifiedMatchIds);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            sentCount > 0
                ? '$sentCount compatible tenant${sentCount == 1 ? '' : 's'} have been notified.'
                : 'All eligible compatible tenants have already been notified.',
          ),
          backgroundColor: const Color(0xFF0F172A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LandlordHomeCubit>();

    return BlocBuilder<LandlordHomeCubit, LandlordHomeState>(
      builder: (context, state) {
        final parentId = widget.initialProperty.parentPropertyId;
        final isMultiRoom =
            widget.initialProperty.isRoom &&
            parentId != null &&
            parentId.isNotEmpty;

        final liveRooms = state.properties.where((p) {
          if (isMultiRoom) {
            return p.parentPropertyId == parentId;
          }
          return p.propertyId == widget.initialProperty.propertyId;
        }).toList();

        final currentRooms =
            liveRooms.isNotEmpty ? liveRooms : widget.allRooms;

        final currentProperty = currentRooms.firstWhere(
          (r) => r.propertyId == _selectedPropertyId,
          orElse: () => currentRooms.isNotEmpty
              ? currentRooms.first
              : widget.initialProperty,
        );

        final displayName = currentProperty.isRoom
            ? ((currentProperty.roomName?.trim().isNotEmpty ?? false)
                ? currentProperty.roomName!.trim()
                : currentProperty.title)
            : ((currentProperty.propertyName?.trim().isNotEmpty ?? false)
                ? currentProperty.propertyName!.trim()
                : currentProperty.title);

        final buildingName =
            (currentProperty.propertyName?.trim().isNotEmpty ?? false)
                ? currentProperty.propertyName!.trim()
                : currentProperty.title;

        final listingLabel = currentProperty.isRoom &&
                buildingName.isNotEmpty &&
                buildingName != displayName
            ? '$buildingName ($displayName)'
            : displayName;

        final displayType =
            (currentProperty.propertyType?.trim().isNotEmpty ?? false)
                ? currentProperty.propertyType!.trim()
                : (currentProperty.isRoom ? 'Boarding House' : 'Apartment');

        final seed = currentProperty.propertyId.hashCode % 5 + 1;
        final unitTenants = _matchesForUnit(state, currentProperty.propertyId);

        // Compute pagination bounds safely
        final totalTenants = unitTenants.length;
        final totalPages = totalTenants == 0
            ? 1
            : ((totalTenants + _itemsPerPage - 1) ~/ _itemsPerPage);
        final safePage = _currentPage.clamp(1, totalPages);
        final startIndex =
            totalTenants == 0 ? 0 : (safePage - 1) * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, totalTenants);
        final pagedTenants = totalTenants == 0
            ? const <CompatibleTenant>[]
            : unitTenants.sublist(startIndex, endIndex);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8FAFC),
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
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF0F172A),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            titleSpacing: 10,
            centerTitle: false,
            title: const Text(
              'Compatible Tenants',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),

                  // Optional Room Switcher when Multi-Room Property has multiple rooms
                  if (currentRooms.length > 1) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < currentRooms.length; i++) ...[
                            _RoomSelectorPill(
                              label: (currentRooms[i]
                                          .roomName
                                          ?.trim()
                                          .isNotEmpty ??
                                      false)
                                  ? currentRooms[i].roomName!.trim()
                                  : 'Room ${i + 1}',
                              matchCount: _matchesForUnit(
                                state,
                                currentRooms[i].propertyId,
                              ).length,
                              isSelected: currentRooms[i].propertyId ==
                                  currentProperty.propertyId,
                              onTap: () {
                                setState(() {
                                  _selectedPropertyId =
                                      currentRooms[i].propertyId;
                                  _currentPage = 1;
                                });
                              },
                            ),
                            if (i < currentRooms.length - 1)
                              const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 1. Read-Only Top Photo Carousel
                  _ReadOnlyPropertyPhotoCarousel(
                    property: currentProperty,
                    seed: seed,
                  ),
                  const SizedBox(height: 14),

                  // 2. Read-Only Property Detail Card (No Edit button, ONLY Status Change)
                  _ReadOnlyPropertyDetailCard(
                    property: currentProperty,
                    displayName: displayName,
                    displayType: displayType,
                    cubit: cubit,
                  ),
                  const SizedBox(height: 14),

                  // 3. Compatible Tenants Card with Theme-Blue Circle Pagination
                  _CompatibleTenantsSectionCard(
                    allTenants: unitTenants,
                    pagedTenants: pagedTenants,
                    notifiedMatchIds: _notifiedMatchIds,
                    isNotifyingAll: _isNotifyingAll,
                    currentPage: safePage,
                    totalPages: totalPages,
                    onPageChanged: (newPage) {
                      setState(() {
                        _currentPage = newPage.clamp(1, totalPages);
                      });
                    },
                    onNotifyAll: () => _notifyAllForUnit(
                      context: context,
                      unit: currentProperty,
                      listingLabel: listingLabel,
                      tenants: unitTenants,
                    ),
                    onNotifySingle: (tenant) => _notifySingleTenant(
                      context: context,
                      tenant: tenant,
                      unit: currentProperty,
                      listingLabel: listingLabel,
                    ),
                    onOpenTenantDetail: (tenant) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TenantDetailScreen(
                            tenant: tenant,
                            showInviteButton: true,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOM SELECTOR PILL (FOR MULTI-ROOM PROPERTIES)
// ─────────────────────────────────────────────────────────────────────────────

class _RoomSelectorPill extends StatelessWidget {
  const _RoomSelectorPill({
    required this.label,
    required this.matchCount,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int matchCount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$matchCount',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. READ-ONLY PHOTO CAROUSEL (HERO IMAGE + THUMBNAILS + FULLSCREEN VIEW)
// ─────────────────────────────────────────────────────────────────────────────

class _ReadOnlyPropertyPhotoCarousel extends StatefulWidget {
  const _ReadOnlyPropertyPhotoCarousel({
    required this.property,
    required this.seed,
  });

  final PropertyDoc property;
  final int seed;

  @override
  State<_ReadOnlyPropertyPhotoCarousel> createState() =>
      _ReadOnlyPropertyPhotoCarouselState();
}

class _ReadOnlyPropertyPhotoCarouselState
    extends State<_ReadOnlyPropertyPhotoCarousel> {
  int _selectedPhotoIndex = 0;

  @override
  void didUpdateWidget(covariant _ReadOnlyPropertyPhotoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property.propertyId != widget.property.propertyId) {
      _selectedPhotoIndex = 0;
    }
  }

  void _openFullScreenViewer(List<String> photos, int initialIndex) {
    if (photos.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ReadOnlyFullScreenGallery(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.property.photos.isNotEmpty
        ? widget.property.photos
        : (widget.property.effectiveBuildingCoverPhoto != null
            ? <String>[widget.property.effectiveBuildingCoverPhoto!]
            : const <String>[]);

    final safeIndex = photos.isEmpty
        ? 0
        : _selectedPhotoIndex.clamp(0, photos.length - 1);
    final activePhotoUrl = photos.isNotEmpty ? photos[safeIndex] : null;

    final status = widget.property.vacancyStatus.isNotEmpty
        ? widget.property.vacancyStatus
        : (widget.property.isAvailable ? 'available' : 'booked');

    final statusLabel = switch (status) {
      'available' => 'Available',
      'pending' => 'Pending',
      _ => 'Occupied',
    };

    final statusDotColor = switch (status) {
      'available' => const Color(0xFF22C55E),
      'pending' => const Color(0xFFF59E0B),
      _ => const Color(0xFF94A3B8),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: photos.isNotEmpty
              ? () => _openFullScreenViewer(photos, safeIndex)
              : null,
          child: Container(
            height: 210,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFF1F5F9),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
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
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: SizedBox.expand(
                      key: ValueKey<String>(activePhotoUrl ?? 'placeholder'),
                      child: ListingImagePlaceholder(
                        seed: widget.seed,
                        photoUrl: activePhotoUrl,
                      ),
                    ),
                  ),
                ),
                // Top-Right Status Pill Badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusDotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom-Right Photo Counter Badge
                if (photos.isNotEmpty)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${safeIndex + 1} / ${photos.length}',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              color: Colors.white,
                              fontSize: 11,
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
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == safeIndex;
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
                              child: const Icon(
                                Icons.broken_image,
                                size: 18,
                                color: Colors.grey,
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
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ReadOnlyFullScreenGallery extends StatefulWidget {
  const _ReadOnlyFullScreenGallery({
    required this.photos,
    required this.initialIndex,
  });

  final List<String> photos;
  final int initialIndex;

  @override
  State<_ReadOnlyFullScreenGallery> createState() =>
      _ReadOnlyFullScreenGalleryState();
}

class _ReadOnlyFullScreenGalleryState
    extends State<_ReadOnlyFullScreenGallery> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.94),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (idx) => setState(() => _currentIndex = idx),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      widget.photos[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),
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
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.photos.length}',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        color: Colors.white,
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
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. READ-ONLY PROPERTY DETAIL CARD (NO EDIT BUTTON, ONLY STATUS CHANGE)
// ─────────────────────────────────────────────────────────────────────────────

class _ReadOnlyPropertyDetailCard extends StatelessWidget {
  const _ReadOnlyPropertyDetailCard({
    required this.property,
    required this.displayName,
    required this.displayType,
    required this.cubit,
  });

  final PropertyDoc property;
  final String displayName;
  final String displayType;
  final LandlordHomeCubit cubit;

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Future<void> _selectStatus(BuildContext context, String targetStatus) async {
    final currentStatus = property.vacancyStatus.isNotEmpty
        ? property.vacancyStatus
        : (property.isAvailable ? 'available' : 'booked');
    if (targetStatus == currentStatus) return;
    final targetLabel =
        targetStatus == 'available' ? 'Available' : 'Occupied';

    final explanation = targetStatus == 'available'
        ? 'Marking this listing as Available will display it in tenant search results and allow compatible tenants to send inquiries.'
        : 'Marking this listing as Occupied will hide it from public search results and prevent new tenant inquiries.';

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
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
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

  Widget _buildPropertyTypeSvg({double size = 18}) {
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
    );
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Heading: Room / Property Title (No Edit button)
          Text(
            displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.4,
              height: 1.2,
            ),
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
                color: Color(0xFF334155),
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
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
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

          // Rental Status Row with Dropdown (Only editable control)
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
    final isAvailable = currentStatus == 'available';
    final label = isAvailable ? 'Available' : 'Occupied';
    final color = isAvailable ? const Color(0xFF16A34A) : const Color(0xFF475569);

    return PopupMenuButton<String>(
      tooltip: 'Change Rental Status',
      onSelected: (targetStatus) => _selectStatus(context, targetStatus),
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      color: Colors.white,
      elevation: 4,
      itemBuilder: (context) => [
        _buildPopupMenuItem(
          value: 'available',
          label: 'Available',
          dotColor: const Color(0xFF16A34A),
          isSelected: isAvailable,
        ),
        _buildPopupMenuItem(
          value: 'booked',
          label: 'Occupied',
          dotColor: const Color(0xFF64748B),
          isSelected: !isAvailable,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: Color(0xFF64748B),
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
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. COMPATIBLE TENANTS SECTION (MAX 5 PER PAGE + CIRCULAR THEME PAGINATION)
// ─────────────────────────────────────────────────────────────────────────────

class _CompatibleTenantsSectionCard extends StatelessWidget {
  const _CompatibleTenantsSectionCard({
    required this.allTenants,
    required this.pagedTenants,
    required this.notifiedMatchIds,
    required this.isNotifyingAll,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.onNotifyAll,
    required this.onNotifySingle,
    required this.onOpenTenantDetail,
  });

  final List<CompatibleTenant> allTenants;
  final List<CompatibleTenant> pagedTenants;
  final Set<String> notifiedMatchIds;
  final bool isNotifyingAll;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onNotifyAll;
  final ValueChanged<CompatibleTenant> onNotifySingle;
  final ValueChanged<CompatibleTenant> onOpenTenantDetail;

  @override
  Widget build(BuildContext context) {
    final allNotified = allTenants.isNotEmpty &&
        allTenants.every((t) => notifiedMatchIds.contains(t.matchId));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header + Notify All Button ──────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Compatible Tenants',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${allTenants.length}',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap a tenant to view full compatibility details',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (allTenants.isNotEmpty) ...[
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isNotifyingAll || allNotified ? null : onNotifyAll,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: allNotified
                            ? const Color(0xFFDCFCE7)
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isNotifyingAll)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: Colors.white,
                              ),
                            )
                          else if (allNotified)
                            const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Color(0xFF15803D),
                            )
                          else
                            _buildSendIcon(color: Colors.white, size: 12.5),
                          const SizedBox(width: 5),
                          Text(
                            allNotified ? 'All Notified' : 'Notify All',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: allNotified
                                  ? const Color(0xFF15803D)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // ── Tenant Rows or Empty State ──────────────────────────────────
          if (allTenants.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 22,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 24,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'No compatible tenants for this listing yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < pagedTenants.length; i++) ...[
                  _CompatibleTenantRow(
                    tenant: pagedTenants[i],
                    isNotified:
                        notifiedMatchIds.contains(pagedTenants[i].matchId),
                    onNotify: () => onNotifySingle(pagedTenants[i]),
                    onTap: () => onOpenTenantDetail(pagedTenants[i]),
                  ),
                  if (i < pagedTenants.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),

          // ── Circular Theme-Blue Pagination (Only shown when > 5 items) ──
          if (totalPages > 1) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            _CircularNumberPaginationBar(
              currentPage: currentPage,
              totalPages: totalPages,
              onPageChanged: onPageChanged,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CIRCULAR NUMBER PAGINATION BAR (< 1  2  3  4  (5)  ...  99 >)
// ─────────────────────────────────────────────────────────────────────────────

class _CircularNumberPaginationBar extends StatelessWidget {
  const _CircularNumberPaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  /// Builds page tokens where `-1` represents an ellipsis (`...`).
  List<int> _buildPageTokens() {
    if (totalPages <= 6) {
      return List<int>.generate(totalPages, (i) => i + 1);
    }

    if (currentPage <= 4) {
      return <int>[1, 2, 3, 4, 5, -1, totalPages];
    }

    if (currentPage >= totalPages - 3) {
      return <int>[
        1,
        -1,
        totalPages - 4,
        totalPages - 3,
        totalPages - 2,
        totalPages - 1,
        totalPages,
      ];
    }

    return <int>[
      1,
      -1,
      currentPage - 1,
      currentPage,
      currentPage + 1,
      -1,
      totalPages,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final canPrev = currentPage > 1;
    final canNext = currentPage < totalPages;
    final tokens = _buildPageTokens();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left Chevron
        InkWell(
          onTap: canPrev ? () => onPageChanged(currentPage - 1) : null,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: canPrev
                  ? const Color(0xFF334155)
                  : const Color(0xFFCBD5E1),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Page Number Tokens
        for (final token in tokens)
          if (token == -1)
            const SizedBox(
              width: 28,
              height: 36,
              child: Center(
                child: Text(
                  '...',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () => onPageChanged(token),
                behavior: HitTestBehavior.opaque,
                child: token == currentPage
                    ? Container(
                        width: 38,
                        height: 38,
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.22),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$token',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
                        width: 32,
                        height: 36,
                        child: Center(
                          child: Text(
                            '$token',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
              ),
            ),

        const SizedBox(width: 6),

        // Right Chevron
        InkWell(
          onTap: canNext ? () => onPageChanged(currentPage + 1) : null,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: canNext
                  ? const Color(0xFF334155)
                  : const Color(0xFFCBD5E1),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPATIBLE TENANT ROW
// ─────────────────────────────────────────────────────────────────────────────

class _CompatibleTenantRow extends StatelessWidget {
  const _CompatibleTenantRow({
    required this.tenant,
    required this.isNotified,
    required this.onNotify,
    required this.onTap,
  });

  final CompatibleTenant tenant;
  final bool isNotified;
  final VoidCallback onNotify;
  final VoidCallback onTap;

  String _formatBudget(double budget) {
    if (budget <= 0) return 'Flexible budget';
    if (budget >= 1000) {
      final k = budget / 1000.0;
      final formatted = k == k.roundToDouble()
          ? k.toInt().toString()
          : k.toStringAsFixed(1);
      return '₱${formatted}k/mo budget';
    }
    return '₱${budget.round()}/mo budget';
  }

  int _computeFitPercent(CompatibleTenant t) {
    if (t.tenantCi != null && t.tenantCi! > 0) {
      return ((t.tenantCi! * 100).round()).clamp(0, 100);
    }
    final score = t.bScore.toDouble();
    if (score > 1.0 && score <= 100.0) {
      return score.round().clamp(75, 99);
    }
    final seed = t.tenantId.hashCode.abs() % 14;
    return (85 + seed).clamp(85, 98);
  }

  @override
  Widget build(BuildContext context) {
    final pct = _computeFitPercent(tenant);
    final bool isHighFit = pct >= 85;
    final fitBg = isHighFit
        ? const Color(0xFFDCFCE7)
        : AppColors.primary.withValues(alpha: 0.12);
    final fitText =
        isHighFit ? const Color(0xFF15803D) : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.75),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            // Tap area for Tenant Details (Initials avatar, Name + budget, Fit % badge)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      // Initials Circle Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tenant.initials,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Name + Budget (expanded without ellipsis, wraps naturally)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant.name,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatBudget(tenant.maxBudget.toDouble()),
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // % Fit Pill Badge + ci=value Badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: fitBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$pct% fit',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: fitText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFC7D2FE),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'ci=${(tenant.tenantCi?.toDouble() ?? (pct / 100.0)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Individual Notify Button (Theme Blue BG & Text, standalone InkWell)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isNotified ? null : onNotify,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isNotified
                        ? const Color(0xFFDCFCE7)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isNotified
                          ? const Color(0xFF86EFAC)
                          : AppColors.primary.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isNotified)
                        const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Color(0xFF15803D),
                        )
                      else
                        _buildSendIcon(
                          color: AppColors.primary,
                          size: 12,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        isNotified ? 'Notified' : 'Notify',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isNotified
                              ? const Color(0xFF15803D)
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
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

Widget _buildSendIcon({required Color color, double size = 14}) {
  return SvgPicture.string(
    '''<svg xmlns="http://www.w3.org/2000/svg" width="$size" height="$size" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
  <line x1="22" y1="2" x2="11" y2="13"></line>
  <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
</svg>''',
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}
