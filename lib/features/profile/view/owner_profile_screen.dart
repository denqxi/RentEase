import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../landlord_home/cubit/landlord_home_cubit.dart';
import '../../../shared/widgets/verified_badge.dart';

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = context.watch<LandlordHomeCubit>().state;

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
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Avatar + name + badge (real account data)
              Center(
                child: Column(
                  children: <Widget>[
                    _OwnerAvatar(photoUrl: state.photoUrl),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.fullName.isEmpty ? 'Owner' : state.fullName,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    if (state.verificationStatus != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      VerifiedBadge(isVerified: state.isVerified),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Verification status card (from ownerProfiles.verificationStatus)
              if (state.verificationStatus != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _VerificationCard(status: state.verificationStatus!),
                ),

              const SizedBox(height: AppSpacing.lg),

              // Menu card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _MenuCard(
                  onLogout: () {
                    context.read<AuthBloc>().add(const AuthSignOutRequested());
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(AppRouter.signIn, (_) => false);
                  },
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
  const _OwnerAvatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return CircleAvatar(
      radius: 48,
      backgroundColor: AppColors.accentSoft,
      backgroundImage: (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
      child: (url != null && url.isNotEmpty)
          ? null
          : Icon(Icons.person, color: AppColors.accent, size: 44),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.status});

  /// 'none' | 'pending' | 'verified' | 'rejected'
  final String status;

  @override
  Widget build(BuildContext context) {
    final submitted = status != 'none';
    final approved = status == 'verified';
    final summary = switch (status) {
      'verified' => 'Your account is verified.',
      'pending' => 'Documents are with an admin for review.',
      'rejected' => 'Your verification was not approved. Resubmit documents.',
      _ => 'Submit documents to get verified.',
    };
    return Container(
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
            icon: submitted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: submitted ? AppColors.matchHigh : AppColors.hint,
            label: 'Documents submitted',
          ),
          const SizedBox(height: AppSpacing.sm),
          _StatusRow(
            icon: approved
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: approved ? AppColors.matchHigh : AppColors.hint,
            label: 'Admin approved',
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(summary, style: AppTextStyles.caption(context)),
        ],
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
            color: AppColors.scrim.withValues(alpha: 0.06),
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
