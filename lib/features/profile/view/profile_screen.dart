import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../core/cubit/app_theme_cubit.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../home/cubit/home_cubit.dart';
import '../../inquiry/view/tenant_inquiries_screen.dart';
import '../../registration/model/user_role.dart';
import '../../shell/cubit/shell_cubit.dart';
import '../cubit/profile_cubit.dart';
import 'account_security_screen.dart';
import 'edit_owner_profile_screen.dart';
import 'edit_rental_preferences_screen.dart';
import 'saved_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color primaryCyan = Color(0xFF00A8F0);
  static const Color textDarkNavy = Color(0xFF14213D);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);
  static const Color softRed = Color(0xFFF26B7A);

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
      color: const Color(0xFF0C2340).withValues(alpha: 0.05),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0C2340).withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Opens a preferences editor; if it saved (and so re-matched), refreshes
  /// Home so the feed reflects the new constraints or weights.
  static Future<void> _openEditor(BuildContext context, Widget editor) async {
    final homeCubit = context.read<HomeCubit>();
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => editor));
    if (saved == true) await homeCubit.refresh();
  }

  static Future<void> _confirmLogOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out?',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(
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
                  backgroundColor: const Color(0xFFEF4444),
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
    final state = context.watch<ProfileCubit>().state;
    final home = context.watch<HomeCubit>().state;
    final homeCubit = context.read<HomeCubit>();
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'tenant@rentease.ph';
    final isGuest = state.userRole == UserRole.guest;

    final displayName = state.fullName.isNotEmpty
        ? state.fullName
        : (user?.displayName?.isNotEmpty ?? false)
            ? user!.displayName!
            : (isGuest ? 'Guest' : 'Tenant');

    final bgColor = isDark ? context.appColors.surface : Colors.white;
    final cardColor = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textColor = isDark ? Colors.white : textDarkNavy;

    final savedCount = home.savedIds.length;
    final inquiryCount = state.inquiryCount;
    final matchesCount = home.listings.length;

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

                  // Top Bar: "Profile" + subtitle
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
                                color: textMuted,
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
                                // Circular Avatar with soft cyan/emerald gradient ring + camera icon
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
                                                      state.photoUrl!.isNotEmpty)
                                                  ? NetworkImage(state.photoUrl!)
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
                                    if (!isGuest)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: InkWell(
                                          onTap: () =>
                                              EditProfileScreen.open(
                                            context,
                                            isOwner: false,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(13),
                                          child: Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      const Color(0xFF0C2340)
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
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

                                // Name + Email (Tenant badge removed)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
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

                  // Unified 3-Stats Card (Saved | Inquiries | Matches)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: cardShadow,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context: context,
                            valueColor: textColor,
                            svgString: AppSvgIcons.save,
                            iconBg: const Color(0xFFE0F3FE),
                            iconColor: primaryCyan,
                            value: '$savedCount',
                            label: 'Saved',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BlocProvider<HomeCubit>.value(
                                  value: homeCubit,
                                  child: const SavedScreen(),
                                ),
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
                            svgString: AppSvgIcons.inquiry,
                            iconBg: const Color(0xFFE0F3FE),
                            iconColor: primaryCyan,
                            value: '$inquiryCount',
                            label: 'Inquiries',
                            onTap: () {
                              if (isGuest) {
                                return;
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const TenantInquiriesScreen(),
                                ),
                              );
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
                            svgString: AppSvgIcons.home,
                            iconBg: const Color(0xFFE0F3FE),
                            iconColor: primaryCyan,
                            value: '$matchesCount',
                            label: 'Matches',
                            onTap: () {
                              try {
                                context.read<ShellCubit>().selectTab(ShellTab.home);
                              } catch (_) {}
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Unified Settings Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: cardShadow,
                    ),
                    child: Column(
                      children: [
                        // Edit personal info (real tenants only)
                        if (!isGuest) ...[
                          _buildMenuItem(
                            svgString: AppSvgIcons.personOutline,
                            title: 'Edit personal info',
                            textColor: textColor,
                            onTap: () => EditProfileScreen.open(
                              context,
                              isOwner: false,
                            ),
                          ),
                          _buildDivider(),
                        ],

                        // Rental preferences
                        _buildMenuItem(
                          svgString: AppSvgIcons.preferencesSliders,
                          title: 'Rental preferences',
                          textColor: textColor,
                          onTap: () => _openEditor(
                            context,
                            const EditRentalPreferencesScreen(),
                          ),
                        ),
                        _buildDivider(),

                        // Dark appearance
                        _buildDarkAppearanceItem(context, textColor),

                        // Account & security (real tenants only)
                        if (!isGuest) ...[
                          _buildDivider(),
                          _buildMenuItem(
                            svgString: AppSvgIcons.lockOutline,
                            title: 'Account & security',
                            textColor: textColor,
                            onTap: () => AccountSecurityScreen.open(
                              context,
                              isOwner: false,
                            ),
                          ),
                        ],
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                        child: Row(
                          children: [
                            const AppSvgIcon(
                              svgString: AppSvgIcons.logoutOutline,
                              color: softRed,
                              size: 21,
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
                            const AppSvgIcon(
                              svgString: AppSvgIcons.chevronRight,
                              color: textMutedLight,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'RentEase prototype · v1.0',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: textMutedLight,
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
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
    String? svgString,
    IconData? icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
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

            // Stacked Value + Label
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: valueColor,
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

  Widget _buildMenuItem({
    IconData? icon,
    String? svgString,
    required String title,
    required Color textColor,
    Color? iconColor,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    final effectiveColor = iconColor ?? primaryCyan;
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
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: primaryCyan,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const AppSvgIcon(
              svgString: AppSvgIcons.chevronRight,
              color: textMutedLight,
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
            color: primaryCyan,
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
