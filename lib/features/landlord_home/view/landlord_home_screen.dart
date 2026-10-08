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
import '../widgets/landlord_home_header.dart';
import '../cubit/landlord_home_cubit.dart';
import '../widgets/compatible_tenants_section.dart';

/// Owner home: greeting, the owner's real listings and a preview of
/// compatible tenants (unranked).
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

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutCubic,
    ));
    _entranceScale = Tween<double>(
      begin: 0.985,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutCubic,
    ));

    _bannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1.0,
    );
    _bannerHeight = CurvedAnimation(
      parent: _bannerCtrl,
      curve: Curves.easeInOutCubic,
    );
    _bannerFade = CurvedAnimation(
      parent: _bannerCtrl,
      curve: Curves.easeOut,
    );

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

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LandlordHomeCubit>();
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _entranceFade,
          child: SlideTransition(
            position: _entranceSlide,
            child: ScaleTransition(
              scale: _entranceScale,
              child: BlocBuilder<LandlordHomeCubit, LandlordHomeState>(
                builder: (context, state) {
                  return Column(
                    children: <Widget>[
                      // Fixed top bar — stays stationary on pull down & scroll
                      ColoredBox(
                        color: context.appColors.surface,
                        child: LandlordHomeHeader(
                          userName: state.firstName,
                          photoUrl: state.photoUrl,
                          isVerified: state.isVerified,
                        ),
                      ),
                      // Invisible separation between the top bar and the section below
                      const SizedBox(height: AppSpacing.xs),
                      // Scrollable section with pull-to-refresh
                      Expanded(
                        child: state.errorMessage != null
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
                                    backgroundColor: Colors.white,
                                    edgeOffset: 0,
                                    onRefresh: cubit.refresh,
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
                                                    status:
                                                        state.verificationStatus,
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
                                          child: _PropertyListingsSection(
                                            properties: state.properties,
                                          ),
                                        ),
                                        const SliverToBoxAdapter(
                                          child: SizedBox(height: AppSpacing.lg),
                                        ),
                                        const SliverToBoxAdapter(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: AppSpacing.lg,
                                            ),
                                            child: CompatibleTenantsSection(
                                              limit: 3,
                                            ),
                                          ),
                                        ),
                                        const SliverToBoxAdapter(
                                          child: SizedBox(height: AppSpacing.xl),
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

  @override
  Widget build(BuildContext context) {
    final total = state.properties.length;
    final available = state.availableCount;
    final notAvailable = total - available;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header: Portfolio overview
          const Text(
            'Portfolio overview',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          // 3 Stat Cards
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  label: 'Listings',
                  value: '$total',
                  subtitle: 'Total units',
                  accentColor: const Color(0xFF00B4D8),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: 'Available',
                  value: '$available',
                  subtitle: 'Ready to rent',
                  accentColor: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: 'Not avail.',
                  value: '$notAvailable',
                  subtitle: 'Under contract',
                  accentColor: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
          width: 0.75,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          // Top row: Label on left, colored dot on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Container(
                width: 6.5,
                height: 6.5,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Large number: right aligned (#1B1B1B)
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B1B1B),
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          // Subtitle text: right aligned
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
    this.count,
    this.trailing,
  });

  final String title;
  final VoidCallback onSeeAll;
  final int? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Text(
              'See all',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ── "Your listings" horizontal carousel ──────────────────────────────────────

class _PropertyListingsSection extends StatelessWidget {
  const _PropertyListingsSection({required this.properties});

  final List<PropertyDoc> properties;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionHeader(
          title: 'Your listings',
          count: properties.length,
          onSeeAll: () =>
              Navigator.of(context).pushNamed(AppRouter.ownerProperties),
          trailing: GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRouter.addProperty),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF334155),
                size: 17,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (properties.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                  width: 0.75,
                ),
                boxShadow: <BoxShadow>[
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
                children: <Widget>[
                  const Text(
                    'You have no listings yet. Add a property\nto start matching with tenants.',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRouter.addProperty),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
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
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 270,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: properties.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, i) => _PropertyCardLarge(
                property: properties[i],
                seed: (properties[i].propertyId.hashCode % 5) + 1,
              ),
            ),
          ),
      ],
    );
  }
}

class _PropertyCardLarge extends StatelessWidget {
  const _PropertyCardLarge({required this.property, required this.seed});

  final PropertyDoc property;
  final int seed;

  String _fmt(num value) => value
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final status = property.vacancyStatus;

    return Container(
      width: 220,
      height: 270,
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
          width: 0.75,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 155,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ListingImagePlaceholder(
                  seed: seed,
                  photoUrl:
                      property.photos.isEmpty ? null : property.photos.first,
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _StatusBadge(status: status),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  property.title,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '₱${_fmt(property.monthlyRent)}/mo',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: context.appColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        property.address,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  /// 'available' | 'pending' | 'booked'
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'available' => ('Available', AppColors.matchHigh),
      'booked' => ('Booked', AppColors.indicatorInactive),
      _ => ('Pending', AppColors.matchMedium),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              color: AppColors.onInk,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
