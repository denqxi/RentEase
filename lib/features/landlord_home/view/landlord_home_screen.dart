import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/firestore/models/models.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../../shared/widgets/pending_listing_banner.dart';
import '../../activity/cubit/activity_cubit.dart';
import '../../activity/view/activity_screen.dart';
import '../widgets/landlord_home_header.dart';
import '../cubit/landlord_home_cubit.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import 'property_manager_screen.dart';

// Compiled once instead of on every call.
final RegExp _kThousandsRe = RegExp(r'(\d)(?=(\d{3})+(?!\d))');

/// Owner home: property management dashboard with real listings, live
/// availability controls, and quick actions.
class LandlordHomeScreen extends StatefulWidget {
  const LandlordHomeScreen({super.key});

  @override
  State<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;
  late final Animation<double> _entranceScale;

  late final AnimationController _bannerCtrl;
  late final Animation<double> _bannerHeight;
  late final Animation<double> _bannerFade;
  bool _isBannerDismissed = false;

  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter =
      'all'; // 'all', 'available', 'unavailable', 'pending'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
        );
    _entranceScale = Tween<double>(begin: 0.985, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
    );

    _bannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1.0,
    );
    _bannerHeight = CurvedAnimation(
      parent: _bannerCtrl,
      curve: Curves.easeInOutCubic,
    );
    _bannerFade = CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOut);

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  void _dismissBanner() {
    _bannerCtrl.reverse().then((_) {
      if (mounted) {
        setState(() => _isBannerDismissed = true);
      }
    });
  }

  void _openPropertyManager(
    BuildContext context,
    PropertyDoc property,
    List<PropertyDoc> rooms,
  ) {
    final cubit = context.read<LandlordHomeCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: PropertyManagerScreen(
            initialProperty: property,
            initialRooms: rooms,
          ),
        ),
      ),
    );
  }

  /// Filters properties by search query and vacancy filter.
  List<PropertyDoc> _filterProperties(List<PropertyDoc> properties) {
    final query = _searchController.text.trim().toLowerCase();
    return properties.where((p) {
      if (query.isNotEmpty) {
        final titleMatches = p.title.toLowerCase().contains(query);
        final propNameMatches = (p.propertyName ?? '').toLowerCase().contains(
          query,
        );
        final addressMatches = p.address.toLowerCase().contains(query);
        final roomNameMatches = (p.roomName ?? '').toLowerCase().contains(
          query,
        );
        if (!titleMatches &&
            !propNameMatches &&
            !addressMatches &&
            !roomNameMatches) {
          return false;
        }
      }

      if (_selectedFilter == 'available') {
        if (!p.isAvailable) return false;
      } else if (_selectedFilter == 'occupied' || _selectedFilter == 'unavailable') {
        if (p.isAvailable) return false;
      }
      return true;
    }).toList();
  }

  List<Widget> _propertyItems(
    BuildContext context,
    List<PropertyDoc> allProperties,
    LandlordHomeCubit cubit,
    Map<String, Set<String>> tenantIdsByProperty,
  ) {
    // Distinct compatible tenants across a card's rooms, from the cubit's one
    // owner-wide matches query (cards no longer query Firestore themselves).
    int countFor(Iterable<PropertyDoc> rooms) => {
      for (final r in rooms) ...?tenantIdsByProperty[r.propertyId],
    }.length;

    // 1. Group all rooms by parentPropertyId
    final groups = <String, List<PropertyDoc>>{};
    for (final p in allProperties) {
      final id = p.parentPropertyId;
      if (p.isRoom && id != null && id.isNotEmpty) {
        groups.putIfAbsent(id, () => []).add(p);
      }
    }

    // 2. Filter properties
    final filtered = _filterProperties(allProperties);

    final items = <Widget>[];
    final emitted = <String>{};

    for (final p in filtered) {
      final id = p.parentPropertyId;
      final isGroupedRoom = p.isRoom && id != null && id.isNotEmpty;

      if (!isGroupedRoom) {
        // Entire property / single listing
        final count = countFor([p]);

        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ModernPropertyCard(
              property: p,
              rooms: [p],
              compatibleCount: count,
              onTap: () => _openPropertyManager(context, p, [p]),
            ),
          ),
        );
      } else {
        // Multi-room property
        if (!emitted.add(id)) continue;
        final rooms = groups[id] ?? [p];
        final count = countFor(rooms);

        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ModernPropertyCard(
              property: rooms.first,
              rooms: rooms,
              compatibleCount: count,
              onTap: () => _openPropertyManager(context, rooms.first, rooms),
            ),
          ),
        );
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LandlordHomeCubit>();
    int unreadNotifications = 0;
    try {
      unreadNotifications = context.select<ActivityCubit, int>(
        (c) => c.state.unreadCount,
      );
    } catch (_) {
      // In isolated tests/previews without ActivityCubit
    }

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: Stack(
        children: <Widget>[
          // Subtle top-right gradient — spread softly across the header & upper content
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
                      AppColors.sky200.withValues(alpha: 0.70),
                      AppColors.skyFill.withValues(alpha: 0.35),
                      AppColors.skyFill.withValues(alpha: 0.0),
                    ],
                    stops: const <double>[0.0, 0.45, 0.88],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _entranceFade,
              child: SlideTransition(
                position: _entranceSlide,
                child: ScaleTransition(
                  scale: _entranceScale,
                  child: BlocConsumer<LandlordHomeCubit, LandlordHomeState>(
                    listenWhen: (prev, curr) =>
                        curr.errorMessage != null &&
                        prev.errorMessage != curr.errorMessage &&
                        curr.properties.isNotEmpty,
                    listener: (context, state) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.errorMessage!),
                          backgroundColor: AppColors.destructive,
                        ),
                      );
                      context.read<LandlordHomeCubit>().clearError();
                    },
                    // Only the fields read below; tenant-list reloads
                    // (tenants, tenantsLoading, tenantsError) and search
                    // emissions no longer rebuild the whole home tree.
                    buildWhen: (prev, curr) =>
                        prev.isLoading != curr.isLoading ||
                        prev.errorMessage != curr.errorMessage ||
                        prev.firstName != curr.firstName ||
                        prev.photoUrl != curr.photoUrl ||
                        prev.verificationStatus != curr.verificationStatus ||
                        prev.properties != curr.properties ||
                        prev.tenantIdsByProperty != curr.tenantIdsByProperty,
                    builder: (context, state) {
                      return Column(
                        children: <Widget>[
                          // Fixed top bar — stays stationary on pull down & scroll
                          LandlordHomeHeader(
                            userName: state.firstName,
                            photoUrl: state.photoUrl,
                            isVerified: state.isVerified,
                            hasUnreadNotifications: unreadNotifications > 0,
                            showNotificationDot: unreadNotifications > 0,
                            onNotificationTap: () {
                              try {
                                final activityCubit = context
                                    .read<ActivityCubit>();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        BlocProvider<ActivityCubit>.value(
                                          value: activityCubit,
                                          child: const ActivityScreen(isOwner: true),
                                        ),
                                  ),
                                );
                              } catch (_) {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ActivityScreen(isOwner: true),
                                  ),
                                );
                              }
                            },
                          ),
                          // Invisible separation between the top bar and the section below
                          const SizedBox(height: AppSpacing.xs),
                          // Scrollable section with pull-to-refresh
                          Expanded(
                            child:
                                state.errorMessage != null &&
                                    state.properties.isEmpty
                                ? _ErrorState(
                                    message: state.errorMessage!,
                                    onRetry: cubit.retry,
                                  )
                                : state.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : RefreshIndicator(
                                    color: AppColors.primary,
                                    backgroundColor: AppColors.surface,
                                    edgeOffset: 0,
                                    onRefresh: () async {
                                      await cubit.refresh();
                                    },
                                    child: CustomScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(
                                            parent: BouncingScrollPhysics(),
                                          ),
                                      slivers: <Widget>[
                                        if (state.showPendingBanner &&
                                            !_isBannerDismissed)
                                          SliverToBoxAdapter(
                                            child: SizeTransition(
                                              sizeFactor: _bannerHeight,
                                              child: FadeTransition(
                                                opacity: _bannerFade,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                        AppSpacing.lg,
                                                        0,
                                                        AppSpacing.lg,
                                                        AppSpacing.md,
                                                      ),
                                                  child: PendingListingBanner(
                                                    status: state
                                                        .verificationStatus,
                                                    onClose: _dismissBanner,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        const SliverToBoxAdapter(
                                          child: SizedBox(height: 8),
                                        ),
                                        SliverToBoxAdapter(
                                          child: _StatsRow(state: state),
                                        ),
                                        const SliverToBoxAdapter(
                                          child: SizedBox(height: 32),
                                        ),
                                        SliverToBoxAdapter(
                                          child: _ActivePropertiesHeader(
                                            count: state.properties.length,
                                            searchController: _searchController,
                                            selectedFilter: _selectedFilter,
                                            onFilterChanged: (filter) =>
                                                setState(
                                                  () =>
                                                      _selectedFilter = filter,
                                                ),
                                          ),
                                        ),
                                        const SliverToBoxAdapter(
                                          child: SizedBox(
                                            height: AppSpacing.sm,
                                          ),
                                        ),
                                        if (state.properties.isEmpty)
                                          const SliverToBoxAdapter(
                                            child: _EmptyPropertiesView(),
                                          )
                                        else
                                          SliverPadding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.lg,
                                            ),
                                            sliver: SliverList(
                                              delegate: SliverChildListDelegate(
                                                _propertyItems(
                                                  context,
                                                  state.properties,
                                                  cubit,
                                                  state.tenantIdsByProperty,
                                                ),
                                              ),
                                            ),
                                          ),

                                        const SliverToBoxAdapter(
                                          child: SizedBox(
                                            height: AppSpacing.xl,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: AppTextStyles.body(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Try again',
            variant: AppButtonVariant.outline,
            isSmall: true,
            isFullWidth: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

// ── Stats ─────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});

  final LandlordHomeState state;

  static const String _portfolioHomeSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 403 326" fill="none">
  <path
    d="M89 155 C89 141 95 128 107 119 L173 69 C187 58 205 58 220 69 L286 119 C298 128 305 141 305 155 L305 225 C305 250 286 270 261 270 L133 270 C108 270 89 250 89 225 Z"
    stroke="black"
    stroke-width="22"
    stroke-linecap="round"
    stroke-linejoin="round"/>
  <path
    d="M156 270 V222 C156 200 174 182 197 182 C220 182 237 200 237 222 V270"
    stroke="black"
    stroke-width="22"
    stroke-linecap="round"
    stroke-linejoin="round"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final total = state.properties.length;
    final available = state.availableCount;
    final notAvailable = total - available;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.fieldFill, width: 1.2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.slate900.withValues(alpha: 0.05),
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
          children: <Widget>[
            // Header Row: Portfolio Overview + analytics icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Portfolio Overview',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your listings at a glance',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 3 Stat Cards Row
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    svgString: _portfolioHomeSvg,
                    iconBgColor: AppColors.primary.withValues(alpha: 0.12),
                    iconBorderColor: AppColors.primary.withValues(alpha: 0.35),
                    iconColor: AppColors.primary,
                    value: '$total',
                    label: 'Total Listings',
                    subtitle: 'All posted',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outline_rounded,
                    iconBgColor: AppColors.green100,
                    iconBorderColor: AppColors.green300,
                    iconColor: AppColors.green600,
                    value: '$available',
                    label: 'Available',
                    subtitle: 'Ready to rent',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    icon: Icons.access_time_rounded,
                    iconBgColor: AppColors.warningFill,
                    iconBorderColor: AppColors.amberBorder200,
                    iconColor: AppColors.amber600,
                    value: '$notAvailable',
                    label: 'Unavailable',
                    subtitle: 'Not for rent',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    this.icon,
    this.svgString,
    required this.iconBgColor,
    required this.iconBorderColor,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.subtitle,
  }) : assert(icon != null || svgString != null);

  final IconData? icon;
  final String? svgString;
  final Color iconBgColor;
  final Color iconBorderColor;
  final Color iconColor;
  final String value;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.slate50.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.slate200.withValues(alpha: 0.65),
          width: 0.65,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Top Row: Rounded Edge Icon with border on Left, Large Value on Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: iconBgColor,
                  border: Border.all(
                    color: iconBorderColor.withValues(alpha: 0.7),
                    width: 0.65,
                  ),
                ),
                alignment: Alignment.center,
                child: svgString != null
                    ? AppSvgIcon(
                        svgString: svgString!,
                        size: 17,
                        color: iconColor,
                      )
                    : Icon(icon, size: 17, color: iconColor),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Label
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          // Subtitle
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              color: AppColors.slate400,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

// ── "Active Properties" header with Search and Filter Chips ─────────────────

class _ActivePropertiesHeader extends StatelessWidget {
  const _ActivePropertiesHeader({
    required this.count,
    required this.searchController,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final int count;
  final TextEditingController searchController;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Title row: "Active Properties (count)" + Add Button
          Row(
            children: <Widget>[
              const Text(
                'Active Properties',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200, width: 1),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate500,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRouter.addProperty),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.slate200,
                      width: 1,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.scrim.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.slate900,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Tap any card directly to manage units & tenants.',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.slate400,
            ),
          ),
          const SizedBox(height: 14),

          // Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.slate200),
              boxShadow: [
                BoxShadow(
                  color: AppColors.slate900.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.slate900,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.slate400,
                  size: 18,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: searchController.clear,
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.slate400,
                          size: 16,
                        ),
                      )
                    : null,
                hintText: 'Search properties, rooms, or address...',
                hintStyle: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12.5,
                  color: AppColors.slate400,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipButton(
                  label: 'All',
                  isSelected: selectedFilter == 'all',
                  onTap: () => onFilterChanged('all'),
                ),
                const SizedBox(width: 8),
                _FilterChipButton(
                  label: 'Available',
                  isSelected: selectedFilter == 'available',
                  onTap: () => onFilterChanged('available'),
                ),
                const SizedBox(width: 8),
                _FilterChipButton(
                  label: 'Occupied',
                  isSelected: selectedFilter == 'occupied' || selectedFilter == 'unavailable',
                  onTap: () => onFilterChanged('occupied'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.slate900 : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.slate900
                : AppColors.slate200,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.surface : AppColors.slate500,
          ),
        ),
      ),
    );
  }
}

// ── Empty properties card ────────────────────────────────────────────────────

class _EmptyPropertiesView extends StatelessWidget {
  const _EmptyPropertiesView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.slate200.withValues(alpha: 0.6),
            width: 0.75,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.slate900.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.slate900.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            const Text(
              'You have no listings yet. Add a property\nto start managing and matching with tenants.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: AppColors.slate500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRouter.addProperty),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.slate900,
                  foregroundColor: AppColors.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Add your first property',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.surface,
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

// ── Modern Property Card ─────────────────────────────────────────────────────

class _ModernPropertyCard extends StatefulWidget {
  const _ModernPropertyCard({
    required this.property,
    required this.rooms,
    required this.onTap,
    this.compatibleCount = 0,
  });

  final PropertyDoc property;
  final List<PropertyDoc> rooms;
  final VoidCallback onTap;
  final int compatibleCount;

  @override
  State<_ModernPropertyCard> createState() => _ModernPropertyCardState();
}

class _ModernPropertyCardState extends State<_ModernPropertyCard> {
  // The compatible-tenant count comes from LandlordHomeCubit
  // (`compatibleCount`), computed from one owner-wide matches query.
  // The rating badge reads the counters on the property/room docs the cubit
  // already streams (no per-card `ratings` reads).

  String _fmt(num value) => value.round().toString().replaceAllMapped(
    _kThousandsRe,
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final rooms = widget.rooms;
    final onTap = widget.onTap;
    final int countToDisplay = widget.compatibleCount;
    final int seed = property.propertyId.hashCode % 5 + 1;
    final int availableCount = rooms.where((r) => r.isAvailable).length;

    final String displayName =
        (property.propertyName?.trim().isNotEmpty ?? false)
        ? property.propertyName!.trim()
        : property.title;

    final String displayType =
        (property.propertyType?.trim().isNotEmpty ?? false)
        ? property.propertyType!.trim()
        : (property.isRoom ? 'Dorm' : 'Studio');

    final bool isEntirePlace = !property.isRoom;

    // Minimum rent across rooms if multi-room, or property's rent
    final num minRent = rooms.isNotEmpty
        ? rooms.map((r) => r.monthlyRent).reduce((a, b) => a < b ? a : b)
        : property.monthlyRent;

    final bool isRoom = property.isRoom;
    final num rentAmount = isRoom ? minRent : property.monthlyRent;
    final String formattedPrice = '₱${_fmt(rentAmount)}';

    final String statusLabel;
    final Color statusDotColor;
    if (isEntirePlace) {
      final effectiveStatus = property.vacancyStatus.isNotEmpty
          ? property.vacancyStatus
          : (property.isAvailable ? 'available' : 'booked');

      statusLabel = effectiveStatus == 'available' ? 'Available' : 'Occupied';
      statusDotColor = effectiveStatus == 'available'
          ? AppColors.matchHigh
          : AppColors.slate400;
    } else {
      statusLabel = availableCount > 0
          ? '$availableCount Available'
          : 'Occupied';

      statusDotColor = availableCount > 0
          ? AppColors.matchHigh
          : AppColors.slate400;
    }
    final int photoCount = property.photos.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.slate200, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero photo ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: ListingImagePlaceholder(
                          seed: seed,
                          photoUrl: isRoom
                              ? (rooms
                                      .map((r) => r.propertyCoverPhoto)
                                      .firstWhere(
                                        (u) => u != null && u.trim().isNotEmpty,
                                        orElse: () => null,
                                      ) ??
                                  property.effectiveBuildingCoverPhoto)
                              : (property.photos.isNotEmpty
                                  ? property.photos.first
                                  : null),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.slate200.withValues(alpha: 0.7),
                                width: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),

                        // Top-left: property type (themed light pill)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.scrim.withValues(alpha: 0.22),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _typeIcon(displayType),
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  displayType,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Top-right: availability (dark pill + status dot)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF0F172A,
                              ).withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: statusDotColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusLabel,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.surface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom-right: photo count (transparent glass badge)
                        if (photoCount > 0)
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
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
                                        size: 11,
                                        color: AppColors.surface,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$photoCount',
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.surface,
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
                ),

              // ── Details ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.slate900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: AppColors.slate400,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      property.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.slate600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildRatingBadge(property, rooms),
                      ],
                    ),
                    const SizedBox(height: 11),
                    const Divider(
                      height: 1,
                      thickness: 0.8,
                      color: AppColors.fieldFill,
                    ),
                    const SizedBox(height: 11),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.groups_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    countToDisplay == 1
                                        ? '1 compatible tenant'
                                        : '$countToDisplay compatible tenants',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: formattedPrice,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const TextSpan(
                                text: ' / month',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.slate500,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge(PropertyDoc property, List<PropertyDoc> rooms) {
    num? effectiveAvg = property.effectiveAvgRating ?? property.avgRating;
    num effectiveCount = property.totalRatings ?? 0;

    if (rooms.isNotEmpty) {
      num sum = 0;
      num count = 0;
      for (final r in rooms) {
        final rAvg = r.effectiveAvgRating ?? r.avgRating;
        final rCount = r.totalRatings ?? 0;
        if (rAvg != null && rCount > 0) {
          sum += (r.ratingSum ?? (rAvg * rCount));
          count += rCount;
        }
      }
      if (count > 0) {
        effectiveAvg = sum / count;
        effectiveCount = count;
      }
    }

    final bool hasRating = effectiveAvg != null && effectiveCount > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.star_rounded,
          size: 16,
          color: AppColors.matchMedium,
        ),
        const SizedBox(width: 3.5),
        if (hasRating) ...[
          Text(
            effectiveAvg.toStringAsFixed(1),
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(width: 2.5),
          Text(
            '($effectiveCount)',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.slate500,
            ),
          ),
        ] else ...[
          const Text(
            '0',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.slate500,
            ),
          ),
        ],
      ],
    );
  }

  IconData _typeIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('apartment') ||
        lower.contains('apt') ||
        lower.contains('condo')) {
      return Icons.apartment_rounded;
    }
    if (lower.contains('house') && !lower.contains('boarding')) {
      return Icons.home_rounded;
    }
    if (lower.contains('boarding') || lower.contains('dorm')) {
      return Icons.bed_rounded;
    }
    return Icons.king_bed_rounded;
  }
}
