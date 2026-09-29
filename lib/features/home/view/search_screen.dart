import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/firestore/models/models.dart';
import '../../../shared/widgets/ci_score_pill.dart';
import '../../../shared/widgets/guest_access_sheet.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../../shared/widgets/match_badge.dart';
import '../../../shared/widgets/verified_badge.dart';
import '../../auth/presentation/current_uid.dart';
import '../../inquiry/view/start_inquiry.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../registration/model/user_role.dart';
import '../../tenant/view/session_filter_sheet.dart';
import '../cubit/home_cubit.dart';
import '../cubit/search_cubit.dart';
import '../data/repositories/home_repository_impl.dart';
import '../model/search_session.dart';
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

    if (isGuest || uid == null) {
      return _SearchView(
        // Guests have no matches, so no Ci — the map view still reads one.
        results: [
          for (final p in MockData.properties)
            {...p, 'tenantCi': p['tenantCi'] ?? 0},
        ],
        isGuest: true,
      );
    }

    return BlocProvider(
      create: (_) =>
          SearchCubit(tenantId: uid, repository: HomeRepositoryImpl()),
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
            isGuest: false,
            isLoading: state.isLoading,
            errorMessage: state.errorMessage,
            onRefresh: context.read<SearchCubit>().load,
          ),
        ),
      ),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView({
    required this.results,
    required this.isGuest,
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
  });

  final List<Map<String, dynamic>> results;
  final TenantProfileDoc? profile;
  final bool isGuest;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function()? onRefresh;

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  // Session filter — local state only, reset when the screen is disposed,
  // never written to Firestore (CLAUDE.md rule 3).
  SearchSession? _session;
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  /// The filter sheet opens on the current session, or on the tenant's own
  /// saved limits (clamped to the sheet's slider ranges) the first time.
  void _showFilterSheet() {
    final profile = widget.profile;
    final budget =
        _session?.maxBudget ?? (profile?.maxBudget ?? MockData.tenantMaxBudget);
    final distance =
        _session?.maxDistanceKm ??
        (profile?.maxDistanceKm ?? MockData.tenantMaxDistance);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SessionFilterSheet(
        initialBudget: budget.toDouble().clamp(1000, 10000),
        initialDistance: distance.toDouble().clamp(0.5, 15),
        onApply: (budget, distance) => setState(
          () => _session = SearchSession(
            maxBudget: budget,
            maxDistanceKm: distance,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _displayed {
    final matching = widget.results
        .where((p) => matchesSearchQuery(p, _queryController.text))
        .toList();
    return _session?.apply(matching) ?? matching;
  }

  /// The tenant's saved hard constraints, as chips.
  List<String> get _savedChips {
    if (widget.isGuest) return const ['All listings'];
    final p = widget.profile;
    if (p == null) return const [];
    final gender = p.requiredGender.trim();
    final isAnyGender =
        gender.isEmpty ||
        const ['any', 'all', 'mixed', 'mixed / any'].contains(
          gender.toLowerCase(),
        );
    return [
      isAnyGender ? 'Any gender' : gender,
      if (p.needsWifi) 'WiFi',
      '₱${_fmt(p.maxBudget.round())} max',
      '${_trimKm(p.maxDistanceKm)} km',
    ];
  }

  static String _fmt(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  static String _trimKm(num km) =>
      km == km.roundToDouble() ? '${km.round()}' : km.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final properties = _displayed;
    final session = _session;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
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
                  const Spacer(),
                  _HeaderButton(
                    icon: Icons.map_rounded,
                    background: context.appColors.fieldFill,
                    foreground: AppColors.accent,
                    bordered: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MapViewScreen(
                          properties: properties,
                          isGuest: widget.isGuest,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filled accent + dot while a session filter is active.
                  _HeaderButton(
                    icon: Icons.tune_rounded,
                    background: session != null
                        ? AppColors.accent
                        : context.appColors.ink,
                    foreground: AppColors.onInk,
                    showDot: session != null,
                    onTap: _showFilterSheet,
                  ),
                ],
              ),
            ),

            // ── Search input ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: context.appColors.fieldFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _queryController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name, location...',
                    hintStyle: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.hint,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.appColors.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: _queryController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: context.appColors.textSecondary,
                              size: 18,
                            ),
                            onPressed: () =>
                                setState(() => _queryController.clear()),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            SizedBox(height: AppSpacing.sm + 4),

            // ── Filter chips: saved constraints (teal), session (amber) ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  for (final chip in _savedChips) ...[
                    _TealChip(label: chip),
                    const SizedBox(width: 8),
                  ],
                  if (session != null) ...<Widget>[
                    _AmberChip(
                      label: '₱${_fmt(session.maxBudget.round())}',
                      onClose: () => setState(() => _session = null),
                    ),
                    const SizedBox(width: 8),
                    _AmberChip(
                      label: '${_trimKm(session.maxDistanceKm)} km',
                      onClose: () => setState(() => _session = null),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: AppSpacing.sm),

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

            SizedBox(height: AppSpacing.sm),

            // ── Results ────────────────────────────────────────────────
            Expanded(child: _results(context, properties)),
          ],
        ),
      ),
    );
  }

  Widget _results(BuildContext context, List<Map<String, dynamic>> properties) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final String? message;
    if (widget.errorMessage != null) {
      message = widget.errorMessage;
    } else if (widget.results.isEmpty) {
      message =
          'No compatible properties yet. Try widening your budget or '
          'distance from your profile.';
    } else if (properties.isEmpty) {
      message = 'No results for "${_queryController.text.trim()}".';
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
                return SizedBox(height: AppSpacing.lg);
              }
              final p = properties[i];
              final rank = (p['tenantRank'] as num?)?.toInt() ?? 0;
              return _PropertyCard(
                property: p,
                // Guests have no TOPSIS ranking; a stale 0 rank shows none.
                rank: widget.isGuest || rank == 0 ? null : rank,
                isGuest: widget.isGuest,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PropertyDetailScreen(
                      property: p,
                      isGuest: widget.isGuest,
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
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.bordered = false,
    this.showDot = false,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool bordered;
  final bool showDot;

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
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Icon(icon, color: foreground, size: 20),
            if (showDot)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.onInk,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chips ─────────────────────────────────────────────────────────

class _TealChip extends StatelessWidget {
  const _TealChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _AmberChip extends StatelessWidget {
  const _AmberChip({required this.label, required this.onClose});
  final String label;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.amberFill,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.amberText,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, size: 12, color: AppColors.amberText),
          ),
        ],
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
  });

  final Map<String, dynamic> property;

  /// TOPSIS rank, or null when there is none to show (guests).
  final int? rank;
  final bool isGuest;
  final VoidCallback onTap;

  String _fmtRent(int rent) => rent.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final int seed = (property['propertyId'] as String).hashCode % 5 + 1;
    final tenantCi = property['tenantCi'] as num?;
    final int rent = (property['monthlyRent'] as num).toInt();
    final bool isVerified = property['isVerified'] as bool? ?? false;
    final num? distance = property['distance'] as num?;
    final bool isOutside = property['isOutsidePreference'] == true;
    final num budgetExcess = (property['budgetExcess'] as num?) ?? 0;
    final num distanceExcess = (property['distanceExcess'] as num?) ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Image with rank badge overlay ──────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ListingImagePlaceholder(seed: seed),
                    if (rank != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.appColors.ink.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '#$rank',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onInk,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Card body ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          property['title'] as String,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // CLAUDE.md: the search screen shows the raw Ci for
                      // precise comparison (Home uses a percentage).
                      if (isGuest)
                        const MatchBadge(
                          percent: 0,
                          showLabel: true,
                          isLocked: true,
                        )
                      else if (tenantCi != null)
                        CiScorePill(score: tenantCi.toDouble()),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: context.appColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          [
                            property['address'] as String,
                            if (!isGuest && distance != null) '$distance km',
                          ].join(' · '),
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: context.appColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: <Widget>[
                      Text(
                        '₱${_fmtRent(rent)}',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                      Text(
                        '/mo',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (isVerified) const VerifiedBadge(isVerified: true),
                    ],
                  ),

                  if (isOutside) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      [
                        'Outside your session filter',
                        if (budgetExcess > 0) '₱$budgetExcess over budget',
                        if (distanceExcess > 0) '$distanceExcess km farther',
                      ].join(' · '),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.amberText,
                      ),
                    ),
                  ],

                  // CLAUDE.md rule 2: absent, never disabled, when bScore = 0.
                  if (property['bScore'] == 1 || isGuest) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isGuest) {
                            GuestAccessSheet.show(context);
                            return;
                          }
                          startInquiry(
                            context,
                            propertyId: property['propertyId'] as String,
                            matchId: property['matchId'] as String?,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appColors.ink,
                          foregroundColor: AppColors.onInk,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(
                          isOutside ? 'Send Inquiry Anyway' : 'Send Inquiry',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
