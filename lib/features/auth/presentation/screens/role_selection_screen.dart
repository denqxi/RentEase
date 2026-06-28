import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/card_over_hero_layout.dart';
import 'signup_screen.dart';

enum _Role { tenant, owner }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  _Role? _selected;

  @override
  Widget build(BuildContext context) {
    return CardOverHeroLayout(
      hero: const HeroPlaceholder(imageAsset: 'assets/images/building2.png'),
      cardContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'I am a...',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Choose your role to get started with RentEase.',
            style: AppTextStyles.body(context),
          ),
          SizedBox(height: AppSpacing.lg),
          _RoleCard(
            icon: Icons.school_rounded,
            title: 'Tenant',
            subtitle: 'Looking for a boarding house near my school or work.',
            selected: _selected == _Role.tenant,
            isTenant: true,
            onTap: () => setState(() => _selected = _Role.tenant),
          ),
          SizedBox(height: AppSpacing.sm),
          _RoleCard(
            icon: Icons.home_work_rounded,
            title: 'Property Owner',
            subtitle: 'I have a boarding house and want to find qualified tenants.',
            selected: _selected == _Role.owner,
            isTenant: false,
            onTap: () => setState(() => _selected = _Role.owner),
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Continue',
            onPressed: _selected != null
                ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SignupScreen(isOwner: _selected == _Role.owner),
                      ),
                    )
                : null,
          ),
          SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              'Your role cannot be changed after this step.',
              style: AppTextStyles.caption(context).copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.isTenant,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool isTenant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color iconColor;

    if (selected) {
      if (isTenant) {
        bg = AppColors.accentSoft;
        border = AppColors.accent;
        iconColor = AppColors.accent;
      } else {
        bg = context.appColors.ink.withValues(alpha: 0.05);
        border = context.appColors.ink;
        iconColor = context.appColors.ink;
      }
    } else {
      bg = context.appColors.surface;
      border = context.appColors.fieldBorder;
      iconColor = context.appColors.textSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
