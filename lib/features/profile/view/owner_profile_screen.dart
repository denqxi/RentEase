import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/topsis_weight_bar.dart';
import '../../../shared/widgets/verified_badge.dart';

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header row — matches tenant ProfileScreen
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.settings_outlined, size: 24, color: cs.onSurface),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Avatar + name + badge
              Center(
                child: Column(
                  children: <Widget>[
                    _OwnerAvatar(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      MockData.ownerName,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const VerifiedBadge(isVerified: true),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Verification status card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.appColors.fieldFill,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: context.appColors.fieldBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _StatusRow(
                        icon: Icons.check_circle_rounded,
                        color: AppColors.matchHigh,
                        label: 'Documents submitted',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _StatusRow(
                        icon: Icons.check_circle_rounded,
                        color: AppColors.matchHigh,
                        label: 'Admin approved',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Verified since Mar 12, 2025',
                        style: AppTextStyles.caption(context),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // TOPSIS weights
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: <Widget>[
                    Text(
                      'My tenant ranking',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRouter.editOwnerTopsis),
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: <Widget>[
                    TopsisWeightBar(
                      label: 'Budget fit',
                      weight: 0.50,
                      color: AppColors.accent,
                    ),
                    TopsisWeightBar(
                      label: 'Stay duration',
                      weight: 0.30,
                      color: AppColors.accent,
                    ),
                    TopsisWeightBar(
                      label: 'Tenant rating',
                      weight: 0.20,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Ratings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'My ratings',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ...List.generate(
                          5,
                          (_) => Icon(Icons.star_rounded,
                              color: AppColors.matchMedium, size: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '4.8',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ReviewCard(
                      name: 'Maria Andres',
                      stars: 5,
                      text: 'Great landlord! Very responsive.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ReviewCard(
                      name: 'Jana Ramos',
                      stars: 4,
                      text: 'Good place, highly recommended.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Menu card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _MenuCard(
                  onLogout: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRouter.signIn, (_) => false),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'RentEase prototype · v1.0',
                  style: AppTextStyles.caption(context),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        width: 90,
        height: 90,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFDBC59C), Color(0xFF8B6914)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 44),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: color, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.body(context).copyWith(fontSize: 13)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.name,
    required this.stars,
    required this.text,
  });

  final String name;
  final int stars;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: context.appColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                name,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ...List.generate(
                stars,
                (_) => Icon(Icons.star_rounded,
                    color: AppColors.matchMedium, size: 13),
              ),
              if (stars < 5)
                Icon(Icons.star_outline_rounded,
                    color: AppColors.matchMedium, size: 13),
            ],
          ),
          const SizedBox(height: 4),
          Text(text, style: AppTextStyles.caption(context).copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          _MenuRow(
              icon: Icons.mail_outline_rounded,
              label: 'Manage inquiries',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.ownerInquiries)),
          _Divider(),
          _MenuRow(
            icon: Icons.logout_rounded,
            label: 'Log out',
            onTap: onLogout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? AppColors.destructive : AppColors.primary;
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? AppColors.destructive : cs.onSurface,
                ),
              ),
            ),
            if (!isDestructive)
              Icon(Icons.chevron_right,
                  color: cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSpacing.md + 36 + AppSpacing.md,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
