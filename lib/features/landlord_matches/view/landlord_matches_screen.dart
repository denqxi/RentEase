import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/models/models.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../landlord_home/cubit/landlord_home_cubit.dart';
import '../../owner/model/compatible_tenant.dart';
import 'property_compatible_tenants_screen.dart';

/// Owner Matches screen: displays property and room summary cards with their
/// compatible match counts (no individual tenant names on the main list).
/// Tapping any card or unit row opens [PropertyCompatibleTenantsScreen].
class LandlordMatchesScreen extends StatefulWidget {
  const LandlordMatchesScreen({super.key});

  @override
  State<LandlordMatchesScreen> createState() => _LandlordMatchesScreenState();
}

class _LandlordMatchesScreenState extends State<LandlordMatchesScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// Filter option: 'all' | 'room' | 'entire_place'
  String _selectedTypeFilter = 'all';

  /// Tracks matchIds invited during this session across detail screens.
  final Set<String> _notifiedMatchIds = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilter => _selectedTypeFilter != 'all';

  List<_PropertyMatchGroup> _buildPropertyGroups(
    List<PropertyDoc> allProperties,
    Map<String, List<CompatibleTenant>> tenantsByProperty,
    List<CompatibleTenant> flatTenants,
  ) {
    final roomsByParent = <String, List<PropertyDoc>>{};
    for (final p in allProperties) {
      final parentId = p.parentPropertyId;
      if (p.isRoom && parentId != null && parentId.isNotEmpty) {
        roomsByParent.putIfAbsent(parentId, () => <PropertyDoc>[]).add(p);
      }
    }

    List<CompatibleTenant> matchesForProperty(String propertyId) {
      final fromMap = tenantsByProperty[propertyId];
      if (fromMap != null) return fromMap;
      return flatTenants
          .where(
            (t) =>
                t.matchId.endsWith('_$propertyId') ||
                t.matchId.contains(propertyId),
          )
          .toList();
    }

    final groups = <_PropertyMatchGroup>[];
    final emittedParents = <String>{};

    for (final p in allProperties) {
      final parentId = p.parentPropertyId;
      final isGroupedRoom = p.isRoom && parentId != null && parentId.isNotEmpty;

      if (!isGroupedRoom) {
        final unitMatches = matchesForProperty(p.propertyId);
        groups.add(
          _PropertyMatchGroup(
            groupKey: p.propertyId,
            title: p.propertyName?.trim().isNotEmpty == true
                ? p.propertyName!.trim()
                : p.title,
            address: p.address,
            coverPhotoUrl: p.effectiveBuildingCoverPhoto,
            isMultiRoom: false,
            primaryProperty: p,
            allRooms: <PropertyDoc>[p],
            units: <_UnitMatchData>[
              _UnitMatchData(
                unit: p,
                unitLabel: p.isRoom
                    ? (p.roomName?.trim().isNotEmpty == true
                        ? p.roomName!.trim()
                        : p.title)
                    : (p.propertyType?.trim().isNotEmpty == true
                        ? '${p.propertyType!.trim()} Unit'
                        : 'Entire Unit'),
                tenants: unitMatches,
              ),
            ],
          ),
        );
      } else {
        if (!emittedParents.add(parentId)) continue;
        final rooms = roomsByParent[parentId] ?? <PropertyDoc>[p];
        final first = rooms.first;
        final unitList = <_UnitMatchData>[
          for (var i = 0; i < rooms.length; i++)
            _UnitMatchData(
              unit: rooms[i],
              unitLabel: rooms[i].roomName?.trim().isNotEmpty == true
                  ? rooms[i].roomName!.trim()
                  : 'Room ${i + 1}',
              tenants: matchesForProperty(rooms[i].propertyId),
            ),
        ];
        groups.add(
          _PropertyMatchGroup(
            groupKey: parentId,
            title: first.propertyName?.trim().isNotEmpty == true
                ? first.propertyName!.trim()
                : first.title,
            address: first.address,
            coverPhotoUrl: first.effectiveBuildingCoverPhoto,
            isMultiRoom: true,
            primaryProperty: first,
            allRooms: rooms,
            units: unitList,
          ),
        );
      }
    }

    return groups;
  }

  List<_PropertyMatchGroup> _applyFilters(List<_PropertyMatchGroup> groups) {
    final query = _searchController.text.trim().toLowerCase();
    final result = <_PropertyMatchGroup>[];

    for (final g in groups) {
      if (_selectedTypeFilter == 'entire_place' && g.isMultiRoom) {
        continue;
      }
      if (_selectedTypeFilter == 'room' && !g.isMultiRoom) {
        continue;
      }

      final propertyMatchesQuery = query.isEmpty ||
          g.title.toLowerCase().contains(query) ||
          g.address.toLowerCase().contains(query);

      final filteredUnits = <_UnitMatchData>[];
      for (final u in g.units) {
        final unitMatchesQuery =
            propertyMatchesQuery || u.unitLabel.toLowerCase().contains(query);

        final matchingTenants = query.isEmpty || unitMatchesQuery
            ? u.tenants
            : u.tenants
                .where(
                  (t) =>
                      t.name.toLowerCase().contains(query) ||
                      (t.occupation?.toLowerCase().contains(query) ?? false) ||
                      (t.school?.toLowerCase().contains(query) ?? false),
                )
                .toList();

        if (query.isNotEmpty && !unitMatchesQuery && matchingTenants.isEmpty) {
          continue;
        }

        filteredUnits.add(
          _UnitMatchData(
            unit: u.unit,
            unitLabel: u.unitLabel,
            tenants: matchingTenants,
          ),
        );
      }

      if (filteredUnits.isEmpty) continue;

      result.add(
        _PropertyMatchGroup(
          groupKey: g.groupKey,
          title: g.title,
          address: g.address,
          coverPhotoUrl: g.coverPhotoUrl,
          isMultiRoom: g.isMultiRoom,
          primaryProperty: g.primaryProperty,
          allRooms: g.allRooms,
          units: filteredUnits,
        ),
      );
    }

    return result;
  }

  void _openCompatibleTenantsScreen(
    BuildContext context,
    _PropertyMatchGroup group, {
    String? selectedPropertyId,
  }) {
    final cubit = context.read<LandlordHomeCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: PropertyCompatibleTenantsScreen(
            initialProperty: group.primaryProperty,
            allRooms: group.allRooms,
            initialSelectedPropertyId: selectedPropertyId,
            initialNotifiedMatchIds: _notifiedMatchIds,
            onNotifiedMatchIdsChanged: (updated) {
              if (mounted) {
                setState(() {
                  _notifiedMatchIds
                    ..clear()
                    ..addAll(updated);
                });
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LandlordHomeCubit>().state;
    final cubit = context.read<LandlordHomeCubit>();

    final allGroups = _buildPropertyGroups(
      state.properties,
      state.tenantsByProperty,
      state.tenants,
    );
    final visibleGroups = _applyFilters(allGroups);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Soft Top Gradient Background matching the reference design
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFCCF2FE).withValues(alpha: 0.78),
                      const Color(0xFFE0F7FE).withValues(alpha: 0.55),
                      const Color(0xFFF8FAFC).withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Colors.white,
              onRefresh: cubit.reloadTenants,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // ── Header + Search & Pill Filters ───────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        18,
                        AppSpacing.lg,
                        16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Matches',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Compatible tenants for your properties',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Full-width Search Bar
                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A)
                                      .withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 18,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? GestureDetector(
                                        onTap: _searchController.clear,
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Color(0xFF94A3B8),
                                          size: 16,
                                        ),
                                      )
                                    : null,
                                hintText: 'Search property or room...',
                                hintStyle: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Easy-access Filter Pills
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChipPill(
                                  label: 'All Properties',
                                  selected: _selectedTypeFilter == 'all',
                                  onTap: () => setState(
                                    () => _selectedTypeFilter = 'all',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChipPill(
                                  label: 'With Rooms',
                                  selected: _selectedTypeFilter == 'room',
                                  onTap: () => setState(
                                    () => _selectedTypeFilter = 'room',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChipPill(
                                  label: 'Entire Property',
                                  selected:
                                      _selectedTypeFilter == 'entire_place',
                                  onTap: () => setState(
                                    () => _selectedTypeFilter = 'entire_place',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Body States (Loading / Error / Empty / Cards) ────────
                  if (state.isLoading ||
                      (state.tenantsLoading && state.tenants.isEmpty))
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.tenantsError != null && state.tenants.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: 12,
                        ),
                        child: _EmptyOrErrorCard(
                          icon: Icons.error_outline_rounded,
                          title: 'Could not load matches',
                          subtitle: state.tenantsError!,
                          actionLabel: 'Try Again',
                          onAction: cubit.reloadTenants,
                        ),
                      ),
                    )
                  else if (state.properties.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: 12,
                        ),
                        child: _EmptyOrErrorCard(
                          icon: Icons.home_work_outlined,
                          title: 'No properties listed yet',
                          subtitle:
                              'Create a property or room listing first to start seeing compatible tenants here.',
                        ),
                      ),
                    )
                  else if (visibleGroups.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: 12,
                        ),
                        child: _EmptyOrErrorCard(
                          icon: Icons.people_outline_rounded,
                          title: _searchController.text.trim().isNotEmpty ||
                                  _hasActiveFilter
                              ? 'No matching results'
                              : 'No compatible tenants yet',
                          subtitle: _searchController.text.trim().isNotEmpty ||
                                  _hasActiveFilter
                              ? 'Try adjusting your search or filter selection.'
                              : 'Compatible tenants whose preferences pass your property rules will automatically appear here.',
                          actionLabel: _hasActiveFilter ? 'Reset Filter' : null,
                          onAction: _hasActiveFilter
                              ? () {
                                  setState(() {
                                    _selectedTypeFilter = 'all';
                                  });
                                }
                              : null,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        4,
                        AppSpacing.lg,
                        110,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final group = visibleGroups[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _PropertyMatchesCard(
                                group: group,
                                onTapPropertyHeader: () =>
                                    _openCompatibleTenantsScreen(
                                  context,
                                  group,
                                ),
                                onTapUnit: (unit) =>
                                    _openCompatibleTenantsScreen(
                                  context,
                                  group,
                                  selectedPropertyId: unit.propertyId,
                                ),
                              ),
                            );
                          },
                          childCount: visibleGroups.length,
                        ),
                      ),
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
// DATA MODELS FOR GROUPING
// ─────────────────────────────────────────────────────────────────────────────

class _PropertyMatchGroup {
  const _PropertyMatchGroup({
    required this.groupKey,
    required this.title,
    required this.address,
    required this.coverPhotoUrl,
    required this.isMultiRoom,
    required this.primaryProperty,
    required this.allRooms,
    required this.units,
  });

  final String groupKey;
  final String title;
  final String address;
  final String? coverPhotoUrl;
  final bool isMultiRoom;
  final PropertyDoc primaryProperty;
  final List<PropertyDoc> allRooms;
  final List<_UnitMatchData> units;

  int get totalMatches =>
      units.fold<int>(0, (sum, u) => sum + u.tenants.length);
}

class _UnitMatchData {
  const _UnitMatchData({
    required this.unit,
    required this.unitLabel,
    required this.tenants,
  });

  final PropertyDoc unit;
  final String unitLabel;
  final List<CompatibleTenant> tenants;
}

// ─────────────────────────────────────────────────────────────────────────────
// OUTER PROPERTY MATCHES CARD (SUMMARY ONLY — NO INDIVIDUAL TENANT NAMES)
// ─────────────────────────────────────────────────────────────────────────────

class _PropertyMatchesCard extends StatelessWidget {
  const _PropertyMatchesCard({
    required this.group,
    required this.onTapPropertyHeader,
    required this.onTapUnit,
  });

  final _PropertyMatchGroup group;
  final VoidCallback onTapPropertyHeader;
  final ValueChanged<PropertyDoc> onTapUnit;

  @override
  Widget build(BuildContext context) {
    final seed = group.primaryProperty.propertyId.hashCode % 5 + 1;
    final matchCount = group.totalMatches;
    final matchLabel = matchCount == 0
        ? 'No matches'
        : '$matchCount ${matchCount == 1 ? 'match' : 'matches'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
          // ── Property Header Row ─────────────────────────────────────
          InkWell(
            onTap: onTapPropertyHeader,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: ListingImagePlaceholder(
                      seed: seed,
                      photoUrl: group.coverPhotoUrl,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Property Title + Address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              group.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Total Match Count Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: matchCount > 0
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    matchLabel,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: matchCount > 0
                          ? AppColors.primary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // ── Unit Summary Rows (No Individual Tenant Names) ──────────
          for (var i = 0; i < group.units.length; i++) ...[
            _UnitSummaryRow(
              unitData: group.units[i],
              onTap: () => onTapUnit(group.units[i].unit),
            ),
            if (i < group.units.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNIT SUMMARY ROW (SHOWS UNIT INFO + "N COMPATIBLE MATCHES" PILL)
// ─────────────────────────────────────────────────────────────────────────────

class _UnitSummaryRow extends StatelessWidget {
  const _UnitSummaryRow({
    required this.unitData,
    required this.onTap,
  });

  final _UnitMatchData unitData;
  final VoidCallback onTap;

  static String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final unit = unitData.unit;
    final tenants = unitData.tenants;
    final matchCount = tenants.length;

    final statusLabel = switch (unit.vacancyStatus) {
      'available' => 'Available',
      'pending' => 'Pending',
      'booked' => 'Occupied',
      _ => unit.isAvailable ? 'Available' : 'Occupied',
    };

    final statusDotColor = switch (statusLabel) {
      'Available' => const Color(0xFF16A34A),
      'Pending' => const Color(0xFFD97706),
      _ => const Color(0xFF64748B),
    };

    final matchesText = matchCount == 0
        ? '0 Matches'
        : '$matchCount Compatible ${matchCount == 1 ? 'Match' : 'Matches'}';

    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Bed / Unit Icon Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  unit.isRoom ? Icons.bed_outlined : Icons.home_work_outlined,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),

              // Unit Name + Price & Status + Compatible Matches Pill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unitData.unitLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '₱${_fmt(unit.monthlyRent)} / month',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: statusDotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusDotColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Summary Pill: "3 Compatible Matches"
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: matchCount > 0
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_alt_outlined,
                                size: 13.5,
                                color: matchCount > 0
                                    ? AppColors.primary
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                matchesText,
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: matchCount > 0
                                      ? AppColors.primary
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _EmptyOrErrorCard extends StatelessWidget {
  const _EmptyOrErrorCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 26, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
