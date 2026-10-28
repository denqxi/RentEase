import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../core/cubit/app_theme_cubit.dart';
import '../../../core/firestore/firestore_collections.dart';
import '../../../core/firestore/property_ratings_aggregator.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../landlord_home/cubit/landlord_home_cubit.dart';
import '../../owner/view/owner_inquiries_screen.dart';
import '../../owner_onboarding/view/document_upload_screen.dart';
import '../../owner_onboarding/view/verification_pending_screen.dart';
import '../../shell/cubit/shell_cubit.dart';
import 'account_security_screen.dart';
import 'edit_owner_profile_screen.dart';
import 'owner_reviews_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});


  static List<BoxShadow> get cardShadow => _OwnerProfileScreenState.cardShadow;

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {

  static const String _portfolioHomeSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3.75 10.5l6.5-5.2a2.75 2.75 0 0 1 3.5 0l6.5 5.2a1.75 1.75 0 0 1 .6 1.37v6.63a2.25 2.25 0 0 1-2.25 2.25h-13A2.25 2.25 0 0 1 3.5 18.5v-6.63a1.75 1.75 0 0 1 .25-1.37z" />
  <path d="M9.5 20.75v-5a2.5 2.5 0 0 1 5 0v5" />
</svg>
''';

  static const String _cameraOutlineSvg = '''
<svg
  xmlns="http://www.w3.org/2000/svg"
  width="36"
  height="36"
  viewBox="0 0 24 24"
  fill="none"
  stroke="#ffffff"
  stroke-width="1.25"
  stroke-linecap="round"
  stroke-linejoin="round"
>
  <path d="M5 7h1a2 2 0 0 0 2 -2a1 1 0 0 1 1 -1h6a1 1 0 0 1 1 1a2 2 0 0 0 2 2h1a2 2 0 0 1 2 2v9a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-9a2 2 0 0 1 2 -2" />
  <path d="M9 13a3 3 0 1 0 6 0a3 3 0 0 0 -6 0" />
</svg>
''';

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inquiriesSub;
  String? _subscribedUid;
  int _inquiriesCount = 0;

  @override
  void initState() {
    super.initState();
    _subscribeStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeStats();
  }

  @override
  void dispose() {
    _inquiriesSub?.cancel();
    super.dispose();
  }

  void _subscribeStats() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    if (uid == _subscribedUid) return;
    _subscribedUid = uid;

    _inquiriesSub?.cancel();

    try {
      // One-shot aggregate count (1 read per 1000 docs) instead of a live
      // listener that re-reads every inquiry doc on each change.
      FirebaseFirestore.instance
          .collection(FirestoreCollections.inquiries)
          .where('ownerId', isEqualTo: uid)
          .count()
          .get()
          .then((agg) {
            if (mounted) setState(() => _inquiriesCount = agg.count ?? 0);
          })
          .catchError((Object e) {
            debugPrint('Error counting owner inquiries: $e');
          });
    } catch (e) {
      debugPrint('Error subscribing to inquiries: $e');
    }
    // The rating is NOT read here: it is the roll-up of the owner's
    // properties' counters, taken in build() from the properties the
    // LandlordHomeCubit already streams (zero extra reads, stays live).
  }

  Future<void> _confirmLogOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.slate900,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13.5,
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
                  backgroundColor: AppColors.destructive,
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
                  'Log out',
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
      context.read<AuthBloc>().add(const AuthSignOutRequested());
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.signIn,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppThemeCubit>().state;
    // Rebuild only when a field shown here changes (not on tenant reloads or
    // search emissions); the record compares structurally.
    final (_, _, _, _, ratingSum, totalReviews) = context.select<
        LandlordHomeCubit, (String, String?, String?, int, num, int)>((c) {
      // Owner rating = roll-up of their own properties' stored counters.
      final rating = OwnerRatingSummary.fromProperties(c.state.properties);
      return (
        c.state.fullName,
        c.state.photoUrl,
        c.state.verificationStatus,
        c.state.properties.length,
        rating.ratingSum,
        rating.totalRatings,
      );
    });
    final rating =
        OwnerRatingSummary(ratingSum: ratingSum, totalRatings: totalReviews);
    final avgRating = rating.average;
    final state = context.read<LandlordHomeCubit>().state;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'josh.samuel@rentease.ph';

    final displayName = state.fullName.isNotEmpty
        ? state.fullName
        : (user?.displayName?.isNotEmpty ?? false)
            ? user!.displayName!
            : 'Josh Samuel';

    final bgColor = isDark ? context.appColors.surface : AppColors.surface;
    final cardColor = isDark ? AppColors.darkCard : AppColors.surface;
    final textColor = isDark ? AppColors.surface : AppColors.ink;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Top decorative sky-blue wave / gradient backdrop
          if (!isDark)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 280,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _TopHeroWavePainter(),
                ),
              ),
            ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),

                  // Top Bar: "Profile" + subtitle (Edit button removed)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Manage your account and preferences',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Profile Information Card with diagonal sky-blue wave detail
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? AppColors.surface.withValues(alpha: 0.08)
                            : AppColors.surface,
                        width: 2,
                      ),
                      boxShadow: cardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          if (!isDark)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _ProfileCardWavePainter(),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                // Circular Avatar with soft white halo ring + cyan-blue camera badge
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.sky400, // Light blue
                                            AppColors.primaryCyan, // Blue
                                            AppColors.emerald500, // Green
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryCyan.withValues(
                                              alpha: 0.14,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: cardColor,
                                        ),
                                        child: CircleAvatar(
                                          radius: 31,
                                          backgroundColor:
                                              AppColors.skyFill,
                                          backgroundImage:
                                              (state.photoUrl != null &&
                                                      state.photoUrl!
                                                          .isNotEmpty)
                                                  ? ResizeImage.resizeIfNeeded(
                                                      330,
                                                      null,
                                                      NetworkImage(
                                                        state.photoUrl!,
                                                      ),
                                                    )
                                                  : null,
                                          child: (state.photoUrl == null ||
                                                  state.photoUrl!.isEmpty)
                                              ? const Icon(
                                                  Icons.person_rounded,
                                                  size: 37,
                                                  color: AppColors.primaryCyan,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: InkWell(
                                        onTap: () =>
                                            EditOwnerProfileScreen.open(
                                          context,
                                        ),
                                        borderRadius: BorderRadius.circular(13),
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.ink
                                                    .withValues(alpha: 0.12),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: AppSvgIcon(
                                              svgString: _cameraOutlineSvg,
                                              color: AppColors.primaryCyan,
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 16),

                                // Name + Verified Badge + Email
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              displayName,
                                              style: TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 17.5,
                                                fontWeight: FontWeight.w800,
                                                color: textColor,
                                                letterSpacing: -0.2,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (state.isVerified) ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: AppColors.primaryCyan,
                                              size: 18,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.mail_outline_rounded,
                                            size: 14,
                                            color: AppColors.slate500,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              email,
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 12.5,
                                                color: AppColors.slate500,
                                                fontWeight: FontWeight.w500,
                                              ),
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
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

              // Unified 3-Stats Card (Listings | Inquiries | Reviews)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: OwnerProfileScreen.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        valueColor: textColor,
                        svgString: _portfolioHomeSvg,
                        iconBg: AppColors.skyFill,
                        iconColor: AppColors.primaryCyan,
                        value: '${state.properties.length}',
                        label: 'Listings',
                        onTap: () {
                          try {
                            context.read<ShellCubit>().selectTab(ShellTab.home);
                          } catch (_) {}
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 1,
                        height: 40,
                        color: isDark
                            ? AppColors.surface.withValues(alpha: 0.08)
                            : AppColors.slate200,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        valueColor: textColor,
                        svgString: AppSvgIcons.inquiry,
                        iconBg: AppColors.skyFill,
                        iconColor: AppColors.primaryCyan,
                        value: '$_inquiriesCount',
                        label: 'Inquiries',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const OwnerInquiriesScreen(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 1,
                        height: 40,
                        color: isDark
                            ? AppColors.surface.withValues(alpha: 0.08)
                            : AppColors.slate200,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        valueColor: textColor,
                        icon: Icons.star_rounded,
                        iconBg: AppColors.amberFill,
                        iconColor: AppColors.matchMedium,
                        value: totalReviews > 0
                            ? avgRating.toStringAsFixed(1)
                            : '0',
                        subCount: '($totalReviews)',
                        label: 'Reviews',
                        onTap: () => OwnerReviewsScreen.open(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Account Verification Card (Compact, single-row white card)
              _buildVerificationCard(
                context,
                state.verificationStatus,
                cardColor,
                textColor,
              ),

              const SizedBox(height: 14),

              // Unified Settings Card (Cyan-blue outline icons without background containers)
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: cardShadow,
                ),
                child: Column(
                  children: [
                    // Edit personal info
                    _buildMenuItem(
                      svgString: AppSvgIcons.personOutline,
                      title: 'Edit personal info',
                      textColor: textColor,
                      onTap: () => EditOwnerProfileScreen.open(context),
                    ),
                    _buildDivider(),

                    // My reviews
                    _buildMenuItem(
                      icon: Icons.star_rounded,
                      iconColor: AppColors.matchMedium,
                      title: 'My reviews',
                      textColor: textColor,
                      trailingText: totalReviews > 0
                          ? '${avgRating.toStringAsFixed(1)} ★'
                          : 'No reviews yet',
                      trailingTextColor: AppColors.slate900,
                      onTap: () => OwnerReviewsScreen.open(context),
                    ),
                    _buildDivider(),

                    // Dark appearance
                    _buildDarkAppearanceItem(context, textColor),
                    _buildDivider(),

                    // Account & security
                    _buildMenuItem(
                      svgString: AppSvgIcons.lockOutline,
                      title: 'Account & security',
                      textColor: textColor,
                      onTap: () => AccountSecurityScreen.open(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Standalone Log Out Card
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: cardShadow,
                ),
                child: InkWell(
                  onTap: () => _confirmLogOut(context),
                  borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          AppSvgIcon(
                            svgString: AppSvgIcons.logoutOutline,
                            color: AppColors.rose500,
                            size: 21,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Log out',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.rose500,
                              ),
                            ),
                          ),
                          AppSvgIcon(
                            svgString: AppSvgIcons.chevronRight,
                            color: AppColors.slate400,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                ),
              ),

              const SizedBox(height: 22),

              // Footer
              const Center(
                child: Text(
                  'RentEase prototype • v1.0',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required Color valueColor,
    IconData? icon,
    String? svgString,
    required Color iconBg,
    required Color iconColor,
    required String value,
    String? subCount,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Icon Badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: svgString != null
                  ? AppSvgIcon(
                      svgString: svgString,
                      size: 17.5,
                      color: iconColor,
                    )
                  : Icon(icon, color: iconColor, size: 18.5),
            ),
            const SizedBox(width: 6),

            // Stacked Value + Label (auto-scales to fit without clipping)
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: valueColor,
                        ),
                        children: [
                          TextSpan(text: value),
                          if (subCount != null) ...[
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: subCount,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationCard(
    BuildContext context,
    String? status,
    Color cardColor,
    Color textColor,
  ) {
    final bool isVerified = status == 'verified';
    final bool isPending = status == 'pending';

    final Color statusColor = isVerified
        ? AppColors.emerald500
        : isPending
            ? AppColors.matchMedium
            : AppColors.destructive;

    final Color statusBg = isVerified
        ? AppColors.emerald50
        : isPending
            ? AppColors.warningFill
            : AppColors.redFill100;

    final IconData icon = isVerified
        ? Icons.check_circle_rounded
        : isPending
            ? Icons.access_time_rounded
            : Icons.error_outline_rounded;

    final String subtitle = isVerified
        ? 'Your account is verified.'
        : isPending
            ? 'Your documents are under review.'
            : 'Please update your documents.';

    final String pillLabel = isVerified
        ? 'Verified'
        : isPending
            ? 'Pending'
            : 'Needs revision';

    return InkWell(
      onTap: () {
        if (isPending) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const VerificationPendingScreen(),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const DocumentUploadScreen(),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account verification',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    softWrap: true,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11.5,
                      color: AppColors.slate500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                pillLabel,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.slate400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    IconData? icon,
    String? svgString,
    required String title,
    required Color textColor,
    Color? iconColor,
    String? trailingText,
    Color? trailingTextColor,
    required VoidCallback onTap,
  }) {
    final effectiveColor = iconColor ?? AppColors.primaryCyan;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            if (svgString != null)
              AppSvgIcon(
                svgString: svgString,
                color: effectiveColor,
                size: 21,
              )
            else if (icon != null)
              Icon(icon, color: effectiveColor, size: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: trailingTextColor ?? AppColors.primaryCyan,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const AppSvgIcon(
              svgString: AppSvgIcons.chevronRight,
              color: AppColors.slate400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkAppearanceItem(BuildContext context, Color textColor) {
    final isDark = context.watch<AppThemeCubit>().state;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        children: [
          const AppSvgIcon(
            svgString: AppSvgIcons.crescentMoon,
            color: AppColors.primaryCyan,
            size: 21,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Dark appearance',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          AppToggle(
            value: isDark,
            onChanged: (_) => context.read<AppThemeCubit>().toggle(),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 54,
      endIndent: 16,
      color: AppColors.fieldFill,
    );
  }
}

/// Paints the soft sky-blue diagonal wave / gradient backdrop at the top of the Profile screen.
class _TopHeroWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Base soft vertical-diagonal gradient fading smoothly into white
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(0.5, -1.0),
        end: Alignment(-0.2, 1.0),
        colors: [
          AppColors.onboardingSky,
          AppColors.tenantFillBlue,
          AppColors.tenantFillBlue,
          AppColors.surface,
        ],
        stops: [0.0, 0.38, 0.72, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // 2. Soft diagonal sky-blue wave ribbon sweeping from top-right
    final topRightWave = Path()
      ..moveTo(size.width * 0.28, 0)
      ..quadraticBezierTo(
        size.width * 0.56,
        size.height * 0.42,
        size.width,
        size.height * 0.58,
      )
      ..lineTo(size.width, 0)
      ..close();

    final topRightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          AppColors.sky400.withValues(alpha: 0.48),
          AppColors.skyFill.withValues(alpha: 0.18),
          AppColors.surface.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawPath(topRightWave, topRightPaint);

    // 3. Subtle secondary diagonal wave on the left-middle behind the profile card
    final leftWave = Path()
      ..moveTo(0, size.height * 0.34)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.55,
        size.width * 0.42,
        size.height * 0.85,
      )
      ..lineTo(0, size.height * 0.85)
      ..close();

    final leftWavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.onboardingSky.withValues(alpha: 0.35),
          AppColors.surface.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawPath(leftWave, leftWavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints the soft diagonal sky-blue wave accents inside the Profile Information Card.
class _ProfileCardWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Subtle horizontal base gradient (pure white on left, soft ice-blue on right)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.topRight,
        colors: [
          AppColors.surface,
          AppColors.tenantFillBlue,
          AppColors.tenantFillBlue,
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Outer diagonal sky-blue ribbon on the right side
    final ribbonOuter = Path()
      ..moveTo(size.width * 0.62, 0)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.55,
        size.width * 0.36,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();

    final outerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          AppColors.onboardingSky.withValues(alpha: 0.48),
          AppColors.skyFill.withValues(alpha: 0.22),
        ],
      ).createShader(rect);
    canvas.drawPath(ribbonOuter, outerPaint);

    // 3. Inner steeper diagonal highlight ribbon on the far right
    final ribbonInner = Path()
      ..moveTo(size.width * 0.80, 0)
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.52,
        size.width * 0.54,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();

    final innerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          AppColors.sky400.withValues(alpha: 0.42),
          AppColors.onboardingSky.withValues(alpha: 0.15),
        ],
      ).createShader(rect);
    canvas.drawPath(ribbonInner, innerPaint);

    // 4. Soft bottom-right white sheen curve
    final bottomSheen = Path()
      ..moveTo(size.width * 0.68, size.height)
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.65,
        size.width,
        size.height * 0.42,
      )
      ..lineTo(size.width, size.height)
      ..close();

    final sheenPaint = Paint()
      ..color = AppColors.surface.withValues(alpha: 0.38);
    canvas.drawPath(bottomSheen, sheenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

