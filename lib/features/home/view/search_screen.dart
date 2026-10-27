

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_options.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../core/firestore/models/models.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/guest_access_sheet.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../auth/presentation/current_uid.dart';
import '../../matching/domain/entities/mismatch_reason.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../registration/model/user_role.dart';
import '../../tenant/view/session_filter_sheet.dart';
import '../cubit/home_cubit.dart';
import '../cubit/search_cubit.dart';
import '../data/repositories/home_repository_impl.dart';
import '../model/search_session.dart';
import '../widgets/listing_card_large.dart' show ListingCardLarge;
import 'map_view_screen.dart';
import 'property_detail_screen.dart';

/// Search tab — the tenant's compatible listings, ranked by TOPSIS Ci
/// (CLAUDE.md rule 9), with a text search and a local-only session filter.
/// Guests browse every listing from local sample data instead.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isGuest = context.select<ProfileCubit, bool>(
      (c) => c.state.userRole == UserRole.guest,
    );
    final uid = currentUidOrNull(context);

    if (isGuest) {
      // Guests browse the public newest-available feed: unranked, no Ci, no
      // profile (the rules let signed-out visitors read nothing else).
      return BlocProvider(
        create: (_) => SearchCubit.guest(repository: HomeRepositoryImpl()),
        child: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) => _SearchView(
            results: state.results,
            isGuest: true,
            isLoading: state.isLoading,
            errorMessage: state.errorMessage,
            onRefresh: context.read<SearchCubit>().load,
          ),
        ),
      );
    }
    if (uid == null) {
      // Signed out outside guest mode (or the offline screenshot harness):
      // nothing to read.
      return const _SearchView(results: [], isGuest: false);
    }

    return BlocProvider(
      create: (_) =>
          SearchCubit(tenantId: uid, repository: HomeRepositoryImpl())
            ..setIncludeNonMatching(true),
      child: BlocListener<HomeCubit, HomeState>(
        // Home's "Other listings > See more" opens this tab with the
        // session-only non-match toggle already on (never persisted).
        listenWhen: (prev, curr) =>
            prev.searchNonMatchesRequests != curr.searchNonMatchesRequests,
        listener: (context, _) =>
            context.read<SearchCubit>().setIncludeNonMatching(true),
        child: BlocListener<HomeCubit, HomeState>(
          // Home re-runs matching when opened or pulled (CLAUDE.md engine
          // trigger b). Search only reads the cached results, so reload once
          // that finishes rather than computing anything itself (rule 7).
          listenWhen: (prev, curr) => prev.isLoading && !curr.isLoading,
          listener: (context, _) => context.read<SearchCubit>().load(),
          child: BlocBuilder<SearchCubit, SearchState>(
            builder: (context, state) => _SearchView(
              results: state.results,
              profile: state.profile,
              nonMatches: state.nonMatches,
              includeNonMatching: state.includeNonMatching,
              isLoadingNonMatches: state.isLoadingNonMatches,
              nonMatchesFailed: state.nonMatchesFailed,
              onToggleNonMatching: context
                  .read<SearchCubit>()
                  .setIncludeNonMatching,
              isGuest: false,
              isLoading: state.isLoading,
              errorMessage: state.errorMessage,
              onRefresh: context.read<SearchCubit>().load,
              searchNonMatchesRequests: context.select<HomeCubit, int>(
                (c) => c.state.searchNonMatchesRequests,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum SearchCategoryTab {
  compatible,
  filterMatches,
  other,
}

class _SearchView extends StatefulWidget {
  const _SearchView({
    required this.results,
    required this.isGuest,
    this.profile,
    this.nonMatches = const [],
    this.includeNonMatching = false,
    this.isLoadingNonMatches = false,
    this.nonMatchesFailed = false,
    this.onToggleNonMatching,
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
    this.searchNonMatchesRequests = 0,
  });

  final List<Map<String, dynamic>> results;
  final TenantProfileDoc? profile;

  /// View-only listings outside the saved preferences.
  final List<Map<String, dynamic>> nonMatches;
  final bool includeNonMatching;
  final bool isLoadingNonMatches;
  final bool nonMatchesFailed;
  final ValueChanged<bool>? onToggleNonMatching;
  final bool isGuest;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function()? onRefresh;
  final int searchNonMatchesRequests;

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  // Session filter — local state only, reset when the screen is disposed,
  // never written to Firestore (CLAUDE.md rule 3).
  SearchSession? _session;
  final _queryController = TextEditingController();
  SearchCategoryTab _selectedTab = SearchCategoryTab.compatible;
  SearchCategoryTab _userSelectedTab = SearchCategoryTab.compatible;

  @override
  void initState() {
    super.initState();
    if (widget.searchNonMatchesRequests > 0) {
      _selectedTab = SearchCategoryTab.other;
      _userSelectedTab = SearchCategoryTab.other;
    }
  }

  @override
  void didUpdateWidget(covariant _SearchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchNonMatchesRequests != oldWidget.searchNonMatchesRequests &&
        widget.searchNonMatchesRequests > 0) {
      _selectedTab = SearchCategoryTab.other;
      _userSelectedTab = SearchCategoryTab.other;
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _selectTab(SearchCategoryTab tab) {
    setState(() {
      _userSelectedTab = tab;
      _selectedTab = tab;
    });
  }

  void _onSearchQueryChanged(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _selectedTab = _userSelectedTab;
      });
      return;
    }

    setState(() {
      final categorized = _categorizedListings;

      final currentTabCount = switch (_effectiveTab) {
        SearchCategoryTab.compatible => categorized.compatible.length,
        SearchCategoryTab.filterMatches => categorized.filterMatches.length,
        SearchCategoryTab.other => categorized.others.length,
      };

      // If current tab already has results for this query, stay on it.
      if (currentTabCount > 0) return;

      // Current tab has 0 results: auto-transfer to the tab that has results!
      if (categorized.compatible.isNotEmpty) {
        _selectedTab = SearchCategoryTab.compatible;
      } else if (categorized.filterMatches.isNotEmpty) {
        _selectedTab = SearchCategoryTab.filterMatches;
      } else if (categorized.others.isNotEmpty) {
        _selectedTab = SearchCategoryTab.other;
      }
    });
  }

  void _clearSearch() {
    _queryController.clear();
    setState(() {
      _selectedTab = _userSelectedTab;
    });
  }

  /// The filter sheet opens on the current session, or on the tenant's own
  /// saved limits (clamped to the sheet's slider ranges) the first time.
  void _showFilterSheet() {
    final profile = widget.profile;
    final savedBudget = (profile?.maxBudget ?? AppOptions.defaultMaxBudget)
        .toDouble()
        .clamp(1000, 10000)
        .toDouble();
    final savedDistance =
        (profile?.maxDistanceKm ?? AppOptions.defaultMaxDistanceKm)
            .toDouble()
            .clamp(0.5, 15)
            .toDouble();
    final budget = _session?.maxBudget ?? savedBudget;
    final distance = _session?.maxDistanceKm ?? savedDistance;
    final initialRoomType = _session?.roomType ?? 'Either';
    final initialPropertyTypes = _session?.propertyTypes ?? const <String>{};
    final initialAmenities = _session?.amenities ?? const <String>{};
    final initialGroupSize =
        _session?.groupSize ?? (profile?.groupSize.toInt() ?? 1);
    final initialRequireSmoking =
        _session?.requireSmokingAllowed ?? (profile?.isSmoker ?? false);
    final initialRequirePets =
        _session?.requirePetsAllowed ?? (profile?.hasPet ?? false);
    final initialPoiType = _session?.poiType ?? profile?.poiType ?? 'School';
    final initialPoiLabel =
        _session?.poiLabel ?? profile?.poiLabel ?? 'Saved Location';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => SessionFilterSheet(
        initialBudget: budget.toDouble().clamp(1000, 10000),
        initialDistance: distance.toDouble().clamp(0.5, 15),
        savedBudget: savedBudget,
        savedDistance: savedDistance,
        initialRoomType: initialRoomType,
        initialPropertyTypes: initialPropertyTypes,
        initialAmenities: initialAmenities,
        initialGroupSize: initialGroupSize,
        initialRequireSmoking: initialRequireSmoking,
        initialRequirePets: initialRequirePets,
        initialPoiType: initialPoiType,
        initialPoiLabel: initialPoiLabel,
        profile: profile,
        onReset: () {
          setState(() => _session = null);
        },
        onApply: ({
          required budget,
          required distance,
          required roomType,
          required propertyTypes,
          required amenities,
          required groupSize,
          required requireSmoking,
          required requirePets,
          poiType,
          poiLabel,
          poiLatLng,
        }) {
          final session = SearchSession(
            maxBudget: budget,
            maxDistanceKm: distance,
            roomType: roomType,
            propertyTypes: propertyTypes,
            amenities: amenities,
            groupSize: groupSize,
            requireSmokingAllowed: requireSmoking,
            requirePetsAllowed: requirePets,
            poiType: poiType,
            poiLabel: poiLabel,
          );
          setState(() {
            if (_isSessionActive(session, profile)) {
              _session = session;
            } else {
              _session = null;
            }
          });
        },
      ),
    );
  }

  // Memo for [_categorizedListings]: it is read several times per build and
  // runs the query filter plus [SearchSession.evaluate] over every listing.
  // Inputs are immutable (replaced, never mutated), so identity checks suffice.
  List<Map<String, dynamic>>? _memoResults;
  List<Map<String, dynamic>>? _memoNonMatches;
  TenantProfileDoc? _memoProfile;
  SearchSession? _memoSession;
  String? _memoQuery;
  ({
    List<Map<String, dynamic>> compatible,
    List<Map<String, dynamic>> filterMatches,
    List<Map<String, dynamic>> others,
  })? _memoCategorized;

  ({
    List<Map<String, dynamic>> compatible,
    List<Map<String, dynamic>> filterMatches,
    List<Map<String, dynamic>> others,
  }) get _categorizedListings {
    final cached = _memoCategorized;
    if (cached != null &&
        identical(_memoResults, widget.results) &&
        identical(_memoNonMatches, widget.nonMatches) &&
        identical(_memoProfile, widget.profile) &&
        identical(_memoSession, _session) &&
        _memoQuery == _queryController.text) {
      return cached;
    }
    _memoResults = widget.results;
    _memoNonMatches = widget.nonMatches;
    _memoProfile = widget.profile;
    _memoSession = _session;
    _memoQuery = _queryController.text;
    return _memoCategorized = _computeCategorized();
  }

  ({
    List<Map<String, dynamic>> compatible,
    List<Map<String, dynamic>> filterMatches,
    List<Map<String, dynamic>> others,
  }) _computeCategorized() {
    final matching = widget.results
        .where((p) => matchesSearchQuery(p, _queryController.text))
        .toList();
    final candidateOthers = widget.nonMatches
        .where((p) => matchesSearchQuery(p, _queryController.text))
        .toList();

    if (_session != null) {
      final evaluated = _session!.evaluate(
        matching: matching,
        nonMatches: candidateOthers,
        profile: widget.profile,
      );
      final compatible = evaluated.matches
          .where((p) => p['isFilterMatch'] != true)
          .toList();
      final filterMatches = evaluated.matches
          .where((p) => p['isFilterMatch'] == true)
          .toList();
      final others = evaluated.others;
      return (
        compatible: compatible,
        filterMatches: filterMatches,
        others: others,
      );
    }

    return (
      compatible: matching,
      filterMatches: const <Map<String, dynamic>>[],
      others: candidateOthers,
    );
  }

  SearchCategoryTab get _effectiveTab {
    final categorized = _categorizedListings;
    if (_selectedTab == SearchCategoryTab.filterMatches &&
        categorized.filterMatches.isEmpty &&
        !_hasActiveSessionFilter) {
      return SearchCategoryTab.compatible;
    }
    return _selectedTab;
  }

  List<Map<String, dynamic>> get _displayed {
    if (widget.isGuest) {
      return widget.results
          .where((p) => matchesSearchQuery(p, _queryController.text))
          .toList();
    }
    final categorized = _categorizedListings;
    switch (_effectiveTab) {
      case SearchCategoryTab.compatible:
        return categorized.compatible;
      case SearchCategoryTab.filterMatches:
        return categorized.filterMatches;
      case SearchCategoryTab.other:
        return categorized.others;
    }
  }

  bool get _hasActiveSessionFilter {
    final s = _session;
    if (s == null) return false;
    return _isSessionActive(s, widget.profile);
  }

  static bool _isSessionActive(SearchSession s, TenantProfileDoc? p) {
    final savedBudget =
        (p?.maxBudget ?? AppOptions.defaultMaxBudget).toDouble();
    final savedDistance =
        (p?.maxDistanceKm ?? AppOptions.defaultMaxDistanceKm).toDouble();
    final savedSmoking = p?.isSmoker ?? false;
    final savedPets = p?.hasPet ?? false;
    final savedGroupSize = p?.groupSize.toInt() ?? 1;

    return (s.maxBudget - savedBudget).abs() > 0.01 ||
        (s.maxDistanceKm - savedDistance).abs() > 0.01 ||
        s.roomType != 'Either' ||
        s.propertyTypes.isNotEmpty ||
        s.amenities.isNotEmpty ||
        s.groupSize != savedGroupSize ||
        s.requireSmokingAllowed != savedSmoking ||
        s.requirePetsAllowed != savedPets;
  }

  Widget _buildQuickTabs({
    required BuildContext context,
    required int compatibleCount,
    required int filterMatchesCount,
    required int otherCount,
    required SearchCategoryTab effectiveTab,
    required bool hasActiveSession,
  }) {
    return SizedBox(
      height: 28,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            _TabPill(
              label: 'Compatible',
              count: compatibleCount,
              isSelected: effectiveTab == SearchCategoryTab.compatible,
              onTap: () => _selectTab(SearchCategoryTab.compatible),
            ),
            if (filterMatchesCount > 0 || hasActiveSession) ...[
              const SizedBox(width: 6),
              _TabPill(
                label: 'Filter Matches',
                count: filterMatchesCount,
                isSelected: effectiveTab == SearchCategoryTab.filterMatches,
                isAmber: true,
                onTap: () => _selectTab(SearchCategoryTab.filterMatches),
              ),
            ],
            const SizedBox(width: 6),
            _TabPill(
              label: 'Other',
              count: otherCount,
              isSelected: effectiveTab == SearchCategoryTab.other,
              onTap: () => _selectTab(SearchCategoryTab.other),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final properties = _displayed;
    final hasActiveSession = _hasActiveSessionFilter;
    final categorized = _categorizedListings;
    final effectiveTab = _effectiveTab;
    final savedIds = context.select<HomeCubit, Set<String>>(
      (c) => c.state.savedIds,
    );

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: Stack(
        children: <Widget>[
          // Subtle top-left gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 195,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.05,
                    colors: <Color>[
                      AppColors.onboardingSky.withValues(alpha: 0.70),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search',
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
                          'Find properties matching your preferences',
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
                  const SizedBox(width: 8),
                  _HeaderButton(
                    svgString: AppSvgIcons.mapPinned,
                    background: context.appColors.fieldFill,
                    foreground: AppColors.accent,
                    bordered: true,
                    strokeWidth: 2.0,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MapViewScreen(
                          properties: [
                            ...categorized.compatible,
                            ...categorized.filterMatches,
                          ],
                          isGuest: widget.isGuest,
                          homeCubit: context.read<HomeCubit>(),
                          poi: widget.profile == null
                              ? null
                              : LatLng(
                                  widget.profile!.poiLatLng.latitude,
                                  widget.profile!.poiLatLng.longitude,
                                ),
                          poiLabel: widget.profile?.poiLabel,
                          poiType: widget.profile?.poiType,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search input + Inline Filter button + Reset ────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.slate200,
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.slate900.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _queryController,
                        onChanged: _onSearchQueryChanged,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by name, location...',
                          hintStyle: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: context.appColors.hint,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: context.appColors.textSecondary,
                            size: 19,
                          ),
                          suffixIcon: _queryController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: context.appColors.textSecondary,
                                    size: 16,
                                  ),
                                  onPressed: _clearSearch,
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Filter Button with active indicator
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: hasActiveSession
                          ? AppColors.warningFill
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasActiveSession
                            ? AppColors.matchMedium
                            : AppColors.slate200,
                        width: hasActiveSession ? 1.2 : 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: hasActiveSession
                              ? AppColors.matchMedium.withValues(alpha: 0.2)
                              : AppColors.slate900.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: AppColors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _showFilterSheet,
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 19,
                                color: hasActiveSession
                                    ? AppColors.amber700
                                    : context.appColors.textPrimary,
                              ),
                              if (hasActiveSession)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.amber600,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Reset icon button (only visible when temporary filter is active)
                  if (hasActiveSession) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.slate200,
                          width: 0.8,
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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _session = null),
                          child: const Center(
                            child: Icon(
                              Icons.refresh_rounded,
                              size: 20,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Quick Category Tabs ────────────────────────────────────
            if (!widget.isGuest)
              _buildQuickTabs(
                context: context,
                compatibleCount: categorized.compatible.length,
                filterMatchesCount: categorized.filterMatches.length,
                otherCount: categorized.others.length,
                effectiveTab: effectiveTab,
                hasActiveSession: hasActiveSession,
              ),

            if (widget.nonMatchesFailed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 4,
                ),
                child: Text(
                  "Couldn't load listings outside your preferences.",
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ),

            const SizedBox(height: 10),

            if (!widget.isLoading && widget.errorMessage == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  '${properties.length} '
                  '${properties.length == 1 ? 'property' : 'properties'} found',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // ── Results ────────────────────────────────────────────────
            Expanded(child: _results(context, properties, savedIds)),
          ],
        ),
      ),
    ],
  ),
);
  }

  Widget _results(
    BuildContext context,
    List<Map<String, dynamic>> properties,
    Set<String> savedIds,
  ) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final String? message;
    if (widget.errorMessage != null) {
      message = widget.errorMessage;
    } else if (widget.results.isEmpty && widget.nonMatches.isEmpty) {
      message =
          'No compatible properties yet. Try widening your budget or '
          'distance from your profile.';
    } else if (properties.isEmpty) {
      if (_queryController.text.trim().isNotEmpty) {
        message = 'No results for "${_queryController.text.trim()}".';
      } else if (_effectiveTab == SearchCategoryTab.filterMatches) {
        message = 'No properties matched your temporary search adjustments.';
      } else if (_effectiveTab == SearchCategoryTab.other) {
        message = 'No other properties found outside your preferences.';
      } else {
        message = 'No compatible properties found.';
      }
    } else {
      message = null;
    }

    final list = message != null
        ? ListView(
            // Scrollable so pull-to-refresh still works on an empty state.
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ),
            ],
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: properties.length + 1,
            itemBuilder: (ctx, i) {
              if (i == properties.length) {
                return const SizedBox(height: AppSpacing.lg);
              }
              final p = properties[i];
              final rank = (p['tenantRank'] as num?)?.toInt() ?? 0;
              final homeCubit = context.read<HomeCubit>();
              return _PropertyCard(
                property: p,
                isSaved: savedIds.contains(p['propertyId']),
                onSavedToggle: () {
                  if (widget.isGuest) {
                    GuestAccessSheet.show(context);
                    return;
                  }
                  homeCubit.toggleSaved(p['propertyId'] as String);
                },
                // Guests have no TOPSIS ranking; a stale 0 rank shows none.
                rank: widget.isGuest || rank == 0 ? null : rank,
                isGuest: widget.isGuest,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PropertyDetailScreen(
                      property: p,
                      isGuest: widget.isGuest,
                      homeCubit: homeCubit,
                      profile: widget.profile,
                      // Re-running Home's matching also reloads Search.
                      onPreferencesSaved: widget.isGuest
                          ? null
                          : context.read<HomeCubit>().refresh,
                    ),
                  ),
                ),
              );
            },
          );

    final onRefresh = widget.onRefresh;
    return onRefresh == null
        ? list
        : RefreshIndicator(onRefresh: onRefresh, child: list);
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    this.icon,
    this.svgString,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.bordered = false,
    this.strokeWidth,
  }) : assert(icon != null || svgString != null, 'Either icon or svgString must be provided');

  final IconData? icon;
  final String? svgString;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool bordered;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: bordered
              ? Border.all(color: context.appColors.fieldBorder)
              : null,
        ),
        child: Center(
          child: svgString != null
              ? AppSvgIcon(
                  svgString: svgString!,
                  size: 20,
                  color: foreground,
                  strokeWidth: strokeWidth,
                )
              : Icon(icon, color: foreground, size: 20),
        ),
      ),
    );
  }
}

// ── Category Tab Pill ────────────────────────────────────────────────────

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.isAmber = false,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isAmber;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final Color countBg;
    final Color countText;

    if (isSelected) {
      if (isAmber) {
        bgColor = AppColors.warningFill;
        borderColor = AppColors.matchMedium;
        textColor = AppColors.amber800;
        countBg = AppColors.amberBorder200;
        countText = AppColors.amber900;
      } else {
        bgColor = AppColors.slate900;
        borderColor = AppColors.slate900;
        textColor = AppColors.surface;
        countBg = AppColors.surface.withValues(alpha: 0.2);
        countText = AppColors.surface;
      }
    } else {
      if (isAmber) {
        bgColor = AppColors.surface;
        borderColor = AppColors.amberBorder200;
        textColor = AppColors.amber700;
        countBg = AppColors.warningFill;
        countText = AppColors.amber800;
      } else {
        bgColor = AppColors.surface;
        borderColor = AppColors.slate200;
        textColor = AppColors.slate500;
        countBg = AppColors.fieldFill;
        countText = AppColors.slate600;
      }
    }

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 0.9),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: isAmber
                      ? AppColors.matchMedium.withValues(alpha: 0.16)
                      : AppColors.slate900.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                )
              else
                BoxShadow(
                  color: AppColors.slate900.withValues(alpha: 0.02),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 4.5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: countBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: countText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Property card ────────────────────────────────────────────────────────

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    required this.rank,
    required this.isGuest,
    required this.onTap,
    required this.isSaved,
    required this.onSavedToggle,
  });

  final Map<String, dynamic> property;
  final bool isSaved;
  final VoidCallback onSavedToggle;

  /// TOPSIS rank, or null when there is none to show (guests).
  final int? rank;
  final bool isGuest;
  final VoidCallback onTap;

  static final RegExp _thousandsRe = RegExp(r'(\d)(?=(\d{3})+(?!\d))');

  static String _fmtRent(num value) => value
      .round()
      .toString()
      .replaceAllMapped(_thousandsRe, (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final int seed = (property['propertyId'] as String).hashCode.abs() % 5 + 1;
    final tenantCi = property['tenantCi'] as num?;
    final int matchPercent = tenantCi != null ? (tenantCi * 100).round() : 0;
    final int rent = (property['monthlyRent'] as num).toInt();
    final num? distance = property['distance'] as num?;
    final bool isNonMatch = property['isNonMatch'] == true;
    final bool isFilterMatch = property['isFilterMatch'] == true;
    final bool isOutside = property['isOutsidePreference'] == true;
    final num budgetExcess = (property['budgetExcess'] as num?) ?? 0;
    final num distanceExcess = (property['distanceExcess'] as num?) ?? 0;
    final reasons =
        (property['mismatchReasons'] as List?)?.cast<MismatchReason>() ??
        const <MismatchReason>[];

    final String rawTitle = (property['title'] as String?) ?? 'Property';
    final String? explicitProp = property['propertyName'] as String?;
    final String? explicitRoom = property['roomName'] as String?;
    final (propName, roomOrTitle) = ListingCardLarge.resolveTitles(
      rawTitle: rawTitle,
      explicitPropertyName: explicitProp,
      explicitRoomName: explicitRoom,
    );

    final displayType = ((property['propertyType'] as String?)?.trim().isNotEmpty ?? false)
        ? (property['propertyType'] as String).trim()
        : 'Boarding House';

    final rawPhotos = property['photos'];
    final int photoCount = (rawPhotos is List && rawPhotos.isNotEmpty)
        ? rawPhotos.length
        : ((property['photoUrl'] as String?)?.isNotEmpty ?? false)
            ? 1
            : 0;

    final docObj = property['propertyDoc'];
    final PropertyDoc? pDoc = docObj is PropertyDoc ? docObj : null;
    final avgRating = (property['rating'] as num?)?.toDouble() ??
        pDoc?.effectiveAvgRating ??
        (property['avgRating'] as num?)?.toDouble() ??
        (pDoc?.ratingSum != null && (pDoc?.totalRatings ?? 0) > 0
            ? (pDoc!.ratingSum! / pDoc.totalRatings!).toDouble()
            : null);
    final totalRatings = (property['reviewCount'] as num?)?.toInt() ??
        pDoc?.totalRatings?.toInt() ??
        (property['totalRatings'] as num?)?.toInt() ??
        0;
    final bool hasRating = avgRating != null && totalRatings > 0;

    final Color matchDotColor =
        matchPercent >= 80 ? AppColors.matchHigh : AppColors.matchMedium;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.slate200,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.08),
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
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Photo & Badges ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: SizedBox(
                  height: 155,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: ListingImagePlaceholder(
                          seed: seed,
                          photoUrl: property['photoUrl'] as String?,
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

                      // Top-left: Match score pill & Rank badge (clean white pill with soft shadow)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.slate900.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isNonMatch) ...[
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 12,
                                  color: AppColors.amberPrimary,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  "Doesn't match",
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ] else if (isFilterMatch) ...[
                                const Icon(
                                  Icons.tune_rounded,
                                  size: 12,
                                  color: AppColors.amberPrimary,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Filter Match',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ] else if (rank != null &&
                                  rank! >= 1 &&
                                  rank! <= 3) ...[
                                if (rank == 1)
                                  const Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 15,
                                    color: Color(0xFFFCA917),
                                  )
                                else if (rank == 2)
                                  const Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 15,
                                    color: Color(0xFF94A3B8),
                                  )
                                else
                                  const Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 15,
                                    color: Color(0xFFCD7F32),
                                  ),
                                const SizedBox(width: 5),
                                Text(
                                  '#$rank Top Match',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.slate900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 1,
                                  height: 11,
                                  color: AppColors.slate300,
                                ),
                                const SizedBox(width: 6),
                                if (!isGuest && matchPercent > 0)
                                  Text(
                                    '$matchPercent% Match',
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slate900,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                              ] else if (!isGuest && matchPercent > 0) ...[
                                Icon(
                                  Icons.auto_awesome,
                                  size: 12,
                                  color: matchDotColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$matchPercent% Match',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ] else ...[
                                const Icon(
                                  Icons.lock_outline,
                                  size: 11.5,
                                  color: AppColors.slate500,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Match',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Top-right: Like / Heart button (clean white circular button)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Material(
                          color: AppColors.transparent,
                          child: InkWell(
                            onTap: onSavedToggle,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surface,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.slate900.withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  isSaved
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_outline_rounded,
                                  size: 17,
                                  color: isSaved
                                      ? AppColors.destructive
                                      : AppColors.slate600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom-right: Photo count badge (clean white pill)
                      if (photoCount > 0)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7.5,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.slate900.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_outlined,
                                  size: 12,
                                  color: AppColors.slate600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$photoCount',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900,
                                    letterSpacing: -0.1,
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

              // ── Details ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (propName != null) ...[
                      Text(
                        propName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate700,
                          letterSpacing: -0.1,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],

                    // Prominent row: Room Name / Title on left, Rating on right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            roomOrTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 18.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              letterSpacing: -0.3,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 15.5,
                              color: AppColors.matchMedium,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              hasRating ? avgRating.toStringAsFixed(1) : '0',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate900,
                              ),
                            ),
                            if (hasRating && totalRatings > 0) ...[
                              const SizedBox(width: 2),
                              Text(
                                '($totalRatings)',
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Address row: restricted to 70% width
                    FractionallySizedBox(
                      widthFactor: 0.70,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.slate500,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              [
                                (property['address'] as String?) ?? '',
                                if (!isGuest && distance != null) '$distance km',
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isNonMatch && reasons.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 13,
                            color: AppColors.matchMedium,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              reasons.take(2).map((r) => r.shortLabel).join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.amberText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (isOutside) ...[
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.amberPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.amberPrimary.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.tune_rounded,
                              size: 11,
                              color: AppColors.amberPrimary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                [
                                  'Outside session filter',
                                  if (budgetExcess > 0) '₱$budgetExcess over budget',
                                  if (distanceExcess > 0) '$distanceExcess km farther',
                                ].join(' · '),
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.amber800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (propName == null && (!isNonMatch || reasons.isEmpty))
                      const SizedBox(height: 16.5),
                    const SizedBox(height: 8),
                    const Divider(
                      height: 1,
                      thickness: 0.8,
                      color: AppColors.fieldFill,
                    ),
                    const SizedBox(height: 8),

                    // Details row: Property type on left, Rent on right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const AppSvgIcon(
                              svgString: AppSvgIcons.propertyType,
                              size: 15,
                              color: AppColors.slate900,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              displayType,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate900,
                              ),
                            ),
                          ],
                        ),

                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '₱${_fmtRent(rent)}',
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const TextSpan(
                                text: ' / month',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11.5,
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
}
