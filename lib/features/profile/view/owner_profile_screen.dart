import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../core/cubit/app_theme_cubit.dart';
import '../../../core/firestore/firestore_collections.dart';
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

  static const Color bgIceBlue = _OwnerProfileScreenState.bgIceBlue;
  static const Color primaryCyan = _OwnerProfileScreenState.primaryCyan;
  static const Color textDarkNavy = _OwnerProfileScreenState.textDarkNavy;
  static const Color textMuted = _OwnerProfileScreenState.textMuted;
  static const Color textMutedLight = _OwnerProfileScreenState.textMutedLight;
  static const Color softRed = _OwnerProfileScreenState.softRed;

  static List<BoxShadow> get cardShadow => _OwnerProfileScreenState.cardShadow;

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  static const Color bgIceBlue = Color(0xFFF4F9FD);
  static const Color primaryCyan = Color(0xFF00A8F0);
  static const Color textDarkNavy = Color(0xFF14213D);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);
  static const Color softRed = Color(0xFFF26B7A);

  static const String _portfolioHomeSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="68 42 258 246" fill="none">
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
          color: const Color(0xFF0C2340).withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF0C2340).withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inquiriesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ratingsSub;
  String? _subscribedUid;
  int _inquiriesCount = 0;
  double _avgRating = 0.0;
  int _totalReviews = 0;

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
    _ratingsSub?.cancel();
    super.dispose();
  }

  void _subscribeStats() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    if (uid == _subscribedUid) return;
    _subscribedUid = uid;

    _inquiriesSub?.cancel();
    _ratingsSub?.cancel();

    try {
      _inquiriesSub = FirebaseFirestore.instance
          .collection(FirestoreCollections.inquiries)
          .where('ownerId', isEqualTo: uid)
          .snapshots()
          .listen(
            (snap) {
              if (mounted) {
                setState(() {
                  _inquiriesCount = snap.docs.length;
                });
              }
            },
            onError: (e) {
              debugPrint('Error streaming owner inquiries: $e');
            },
          );
    } catch (e) {
      debugPrint('Error subscribing to inquiries: $e');
    }

    try {
      _ratingsSub = FirebaseFirestore.instance
          .collection(FirestoreCollections.ratings)
          .where('ratedId', isEqualTo: uid)
          .where('raterRole', isEqualTo: 'tenant')
          .snapshots()
          .listen(
            (snap) {
              if (mounted) {
                if (snap.docs.isEmpty) {
                  setState(() {
                    _avgRating = 0.0;
                    _totalReviews = 0;
                  });
                } else {
                  num totalStars = 0;
                  for (final doc in snap.docs) {
                    final data = doc.data();
                    final stars = (data['stars'] as num?) ?? 0;
                    totalStars += stars;
                  }
                  setState(() {
                    _totalReviews = snap.docs.length;
                    _avgRating = totalStars / snap.docs.length;
                  });
                }
              }
            },
            onError: (e) {
              debugPrint('Error streaming owner ratings: $e');
            },
          );
    } catch (e) {
      debugPrint('Error subscribing to ratings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppThemeCubit>().state;
    final state = context.watch<LandlordHomeCubit>().state;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'josh.samuel@rentease.ph';

    final displayName = state.fullName.isNotEmpty
        ? state.fullName
        : (user?.displayName?.isNotEmpty ?? false)
            ? user!.displayName!
            : 'Josh Samuel';

    final bgColor = isDark ? context.appColors.surface : Colors.white;
    final cardColor = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textColor = isDark ? Colors.white : OwnerProfileScreen.textDarkNavy;

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
                                color: OwnerProfileScreen.textMuted,
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
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white,
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
                                            Color(0xFF7DD3FC), // Light blue
                                            Color(0xFF00A8F0), // Blue
                                            Color(0xFF10B981), // Green
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryCyan.withValues(
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
                                              const Color(0xFFD6F0FE),
                                          backgroundImage:
                                              (state.photoUrl != null &&
                                                      state.photoUrl!
                                                          .isNotEmpty)
                                                  ? NetworkImage(
                                                      state.photoUrl!,
                                                    )
                                                  : null,
                                          child: (state.photoUrl == null ||
                                                  state.photoUrl!.isEmpty)
                                              ? const Icon(
                                                  Icons.person_rounded,
                                                  size: 37,
                                                  color: primaryCyan,
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
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF0C2340)
                                                    .withValues(alpha: 0.12),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: AppSvgIcon(
                                              svgString: _cameraOutlineSvg,
                                              color: primaryCyan,
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
                                              color: primaryCyan,
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
                                            color: textMuted,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              email,
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 12.5,
                                                color: textMuted,
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
                        iconBg: const Color(0xFFE0F3FE),
                        iconColor: primaryCyan,
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
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE8EEF5),
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        valueColor: textColor,
                        svgString: AppSvgIcons.inquiry,
                        iconBg: const Color(0xFFE0F3FE),
                        iconColor: primaryCyan,
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
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE8EEF5),
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        valueColor: textColor,
                        icon: Icons.star_rounded,
                        iconBg: const Color(0xFFFEF3D6),
                        iconColor: const Color(0xFFF59E0B),
                        value: _totalReviews > 0
                            ? _avgRating.toStringAsFixed(1)
                            : '0',
                        subCount: '($_totalReviews)',
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
                      icon: Icons.person_outline_rounded,
                      title: 'Edit personal info',
                      textColor: textColor,
                      onTap: () => EditOwnerProfileScreen.open(context),
                    ),
                    _buildDivider(),

                    // My reviews
                    _buildMenuItem(
                      icon: Icons.star_outline_rounded,
                      title: 'My reviews',
                      textColor: textColor,
                      trailingText: '4.8 ★',
                      onTap: () => OwnerReviewsScreen.open(context),
                    ),
                    _buildDivider(),

                    // Dark appearance
                    _buildDarkAppearanceItem(context, textColor),
                    _buildDivider(),

                    // Account & security
                    _buildMenuItem(
                      icon: Icons.lock_outline_rounded,
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
                  onTap: () {
                    context.read<AuthBloc>().add(const AuthSignOutRequested());
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRouter.signIn,
                      (_) => false,
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: softRed,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Log out',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: softRed,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: textMutedLight,
                            size: 20,
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
                    color: textMutedLight,
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
                                color: textMuted,
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
                        color: textMuted,
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
        ? const Color(0xFF10B981)
        : isPending
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    final Color statusBg = isVerified
        ? const Color(0xFFE8F9F1)
        : isPending
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFFEE2E2);

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
                      color: textMuted,
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
              color: textMutedLight,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color textColor,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: primaryCyan, size: 22),
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
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: primaryCyan,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: textMutedLight,
              size: 19,
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
          const Icon(Icons.dark_mode_outlined, color: primaryCyan, size: 22),
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
      color: Color(0xFFF1F5F9),
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
          Color(0xFFC8E7FD),
          Color(0xFFE6F4FE),
          Color(0xFFF6FBFF),
          Colors.white,
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
          const Color(0xFFA7DAFC).withValues(alpha: 0.48),
          const Color(0xFFD5EEFE).withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.0),
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
          const Color(0xFFCBE8FD).withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
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
          Colors.white,
          Color(0xFFF6FBFF),
          Color(0xFFE5F4FE),
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
          const Color(0xFFB5E0FC).withValues(alpha: 0.48),
          const Color(0xFFDDF1FE).withValues(alpha: 0.22),
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
          const Color(0xFF9BD4FB).withValues(alpha: 0.42),
          const Color(0xFFCDEAFE).withValues(alpha: 0.15),
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
      ..color = Colors.white.withValues(alpha: 0.38);
    canvas.drawPath(bottomSheen, sheenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

