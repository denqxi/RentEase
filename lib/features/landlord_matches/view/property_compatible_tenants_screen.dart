import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/models/models.dart';
import '../../activity/data/repositories/notification_repository_impl.dart';
import '../../auth/presentation/current_uid.dart';
import '../../inquiry/data/repositories/inquiry_repository_impl.dart';
import '../../inquiry/domain/services/inquiry_service.dart';
import '../../landlord_home/cubit/landlord_home_cubit.dart';
import '../../landlord_home/view/property_manager_screen.dart';
import '../../landlord_home/view/tenant_detail_screen.dart';
import 'property_header.dart';
import '../../owner/model/compatible_tenant.dart';
import '../../../shared/widgets/app_snack_bar.dart';

/// Dedicated screen opened when tapping a property or room card in the Matches
/// tab. Displays:
/// 1. A slim property header with the rental status (tap for the property)
/// 2. Compatible Tenants list with Notify / Notify All actions and minimal,
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
        backgroundColor: context.appColors.surface,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Invite ${tenant.name}?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.appColors.textPrimary,
          ),
        ),
        content: Text(
          'Invite ${tenant.name} to view "$listingLabel"?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13.5,
            color: context.appColors.textSecondary,
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
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.surface,
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
                  'Invite',
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
      AppSnackBar.show(
        messenger,
        'Unable to identify owner account. Please sign in again.',
        kind: AppSnackKind.error,
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
        AppSnackBar.show(
          messenger,
          '${tenant.name} has been invited.',
          kind: AppSnackKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Bad state: ', '');
        if (msg.toLowerCase().contains('already')) {
          setState(() => _notifiedMatchIds.add(tenant.matchId));
          widget.onNotifiedMatchIdsChanged?.call(_notifiedMatchIds);
        }
        AppSnackBar.show(
          messenger,
          msg,
          kind: msg.toLowerCase().contains('already')
              ? AppSnackKind.info
              : AppSnackKind.error,
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
      AppSnackBar.show(
        messenger,
        'All compatible tenants for this unit are already invited.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Invite all compatible tenants?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.appColors.textPrimary,
          ),
        ),
        content: Text(
          'Invite ${unnotified.length} compatible tenant${unnotified.length == 1 ? '' : 's'} to view "$listingLabel"?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13.5,
            color: context.appColors.textSecondary,
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
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.surface,
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
                  'Invite',
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
      AppSnackBar.show(
        messenger,
        'Unable to identify owner account. Please sign in again.',
        kind: AppSnackKind.error,
      );
      return;
    }

    setState(() => _isNotifyingAll = true);
    int sentCount = 0;
    int failedCount = 0;

    final service = InquiryService(
      repository: InquiryRepositoryImpl(),
      notifications: NotificationRepositoryImpl(),
    );

    for (final t in unnotified) {
      try {
        await service.sendInvite(ownerId: ownerId, matchId: t.matchId);
        sentCount++;
        _notifiedMatchIds.add(t.matchId);
      } catch (e) {
        failedCount++;
        debugPrint('Notify all: sendInvite failed for ${t.matchId}: $e');
      }
    }

    if (mounted) {
      setState(() => _isNotifyingAll = false);
      widget.onNotifiedMatchIdsChanged?.call(_notifiedMatchIds);
      AppSnackBar.show(
        messenger,
        failedCount > 0
        ? '$sentCount invited, $failedCount failed. Please try again for the rest.'
        : sentCount > 0
        ? '$sentCount compatible tenant${sentCount == 1 ? ' has' : 's have'} been invited.'
        : 'All eligible compatible tenants have already been invited.',
        kind: failedCount > 0
            ? AppSnackKind.error
            : sentCount > 0
            ? AppSnackKind.success
            : AppSnackKind.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LandlordHomeCubit>();

    return BlocBuilder<LandlordHomeCubit, LandlordHomeState>(
      // Only these fields are read below; skip rebuilding the whole screen
      // for unrelated emissions (search query, profile, loading flags).
      buildWhen: (prev, curr) =>
          prev.properties != curr.properties ||
          prev.tenants != curr.tenants ||
          prev.tenantsByProperty != curr.tenantsByProperty,
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
          backgroundColor: context.appColors.fieldFill,
          appBar: AppBar(
            backgroundColor: context.appColors.fieldFill,
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
                    color: context.appColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.appColors.fieldBorder.withValues(alpha: 0.6),
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
              'Compatible Tenants',
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

                  // 1. Slim property header
                  PropertyHeader(
                    property: currentProperty,
                    displayName: displayName,
                    onSetStatus: (status) => cubit.setVacancy(
                      currentProperty.propertyId,
                      status,
                    ),
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider.value(
                          value: cubit,
                          child: PropertyManagerScreen(
                            initialProperty: currentProperty,
                            initialRooms: [currentProperty],
                            isSingleRoomView: true,
                          ),
                        ),
                      ),
                    ),
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
          color: isSelected ? context.appColors.textPrimary : context.appColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? context.appColors.textPrimary
                : context.appColors.fieldBorder,
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
                color: isSelected ? context.appColors.surface : context.appColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.appColors.surface.withValues(alpha: 0.18)
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$matchCount',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? context.appColors.surface : context.appColors.link,
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
        color: context.appColors.surface,
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
          // ── Section Header + Notify All Button ──────────────────────────
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allTenants.length == 1
                          ? '1 tenant'
                          : '${allTenants.length} tenants',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap a tenant for details',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              if (allTenants.isNotEmpty) ...[
                Material(
                  color: AppColors.transparent,
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
                            ? AppColors.green100
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
                                color: AppColors.surface,
                              ),
                            )
                          else if (allNotified)
                            const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: AppColors.green700,
                            )
                          else
                            _buildSendIcon(color: context.appColors.surface, size: 12.5),
                          const SizedBox(width: 5),
                          Text(
                            allNotified ? 'All invited' : 'Invite all',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: allNotified
                                  ? AppColors.green700
                                  : AppColors.surface,
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
          Divider(height: 1, thickness: 0.8, color: context.appColors.fieldFill),
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
                color: context.appColors.fieldFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.appColors.fieldBorder,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 24,
                    color: context.appColors.hint,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No compatible tenants for this listing yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < pagedTenants.length; i++) ...[
                  CompatibleTenantRow(
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
            Divider(height: 1, thickness: 0.8, color: context.appColors.fieldFill),
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
                  ? context.appColors.textPrimary
                  : context.appColors.hint,
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Page Number Tokens
        for (final token in tokens)
          if (token == -1)
            SizedBox(
              width: 28,
              height: 36,
              child: Center(
                child: Text(
                  '...',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textSecondary,
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
                              color: AppColors.surface,
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
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: context.appColors.textPrimary,
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
                  ? context.appColors.textPrimary
                  : context.appColors.hint,
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

@visibleForTesting
class CompatibleTenantRow extends StatelessWidget {
  const CompatibleTenantRow({super.key, 
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

  @override
  Widget build(BuildContext context) {
    final notifyButton = Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: isNotified ? null : onNotify,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isNotified
                ? AppColors.green100
                : AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isNotified
                  ? AppColors.green300
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
                  color: AppColors.green700,
                )
              else
                _buildSendIcon(color: AppColors.primary, size: 12),
              const SizedBox(width: 4),
              Text(
                isNotified ? 'Invited' : 'Invite',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isNotified ? AppColors.green700 : context.appColors.link,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.appColors.fieldBorder.withValues(alpha: 0.75),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Initials circle avatar
                if (MediaQuery.textScalerOf(context).scale(1) <= 1.5) ...[
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
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: context.appColors.link,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ],

                // The name gets the full remaining width; badges and the
                // Notify button wrap onto their own line below it so a
                // narrow phone never squeezes the name into a thin column.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              tenant.name,
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.appColors.textPrimary,
                                height: 1.25,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: context.appColors.hint,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      for (final line in [
                        tenant.genderAndGroup,
                        tenant.occupationLabel,
                        tenant.moveInLabel,
                        _formatBudget(tenant.maxBudget.toDouble()),
                      ])
                        Text(
                          line,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12.5,
                            color: context.appColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          // A star only once there is a rating to show.
                          if (tenant.ratingCount > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: AppColors.matchMedium,
                            ),
                            const SizedBox(width: 3),
                          ],
                          Flexible(
                            child: Text(
                              tenant.ratingLabel,
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: context.appColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      notifyButton,
                    ],
                  ),
                ),
              ],
            ),
          ),
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
