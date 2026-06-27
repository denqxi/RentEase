import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// White card containing the profile settings menu rows.
class ProfileMenuCard extends StatelessWidget {
  const ProfileMenuCard({
    required this.darkMode,
    required this.onDarkModeToggle,
    super.key,
  });

  final bool darkMode;
  final VoidCallback onDarkModeToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
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
            icon: Icons.person_outline,
            label: 'Edit profile',
            onTap: () {},
          ),
          const _Divider(),
          _MenuRow(
            icon: Icons.tune_rounded,
            label: 'Edit preferences',
            onTap: () {},
          ),
          const _Divider(),
          _MenuRow(
            icon: Icons.access_time_outlined,
            label: 'Account information',
            onTap: () {},
          ),
          const _Divider(),
          _DarkModeRow(value: darkMode, onToggle: onDarkModeToggle),
          const _Divider(),
          _LogOutRow(onTap: () {}),
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            _IconCircle(icon: icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: AppTextStyles.label.copyWith(fontSize: 15, fontWeight: FontWeight.w500)),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkModeRow extends StatelessWidget {
  const _DarkModeRow({required this.value, required this.onToggle});

  final bool value;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          _IconCircle(icon: Icons.dark_mode_outlined),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Dark appearance',
              style: AppTextStyles.label.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: (_) => onToggle(),
            activeThumbColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _LogOutRow extends StatelessWidget {
  const _LogOutRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.destructive.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.destructive,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Log out',
              style: AppTextStyles.label.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.destructive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.accent, size: 18),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: AppSpacing.md + 36 + AppSpacing.md,
      color: AppColors.fieldBorder,
    );
  }
}
