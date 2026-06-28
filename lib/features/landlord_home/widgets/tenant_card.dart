import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../model/tenant.dart';

/// Row card showing a single compatible tenant with match badge and tags.
class TenantCard extends StatelessWidget {
  const TenantCard({
    required this.tenant,
    required this.onSaveToggle,
    this.onTap,
    super.key,
  });

  final Tenant tenant;
  final VoidCallback onSaveToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _TenantAvatar(tenant: tenant),
              SizedBox(width: AppSpacing.md),
              Expanded(child: _TenantInfo(tenant: tenant)),
              Icon(
                Icons.chevron_right,
                color: context.appColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TenantAvatar extends StatelessWidget {
  const _TenantAvatar({required this.tenant});

  final Tenant tenant;

  static const List<List<Color>> _palettes = <List<Color>>[
    <Color>[Color(0xFFDBC59C), Color(0xFF8B6914)],
    <Color>[Color(0xFF2C3E6B), Color(0xFF0D1B3A)],
    <Color>[Color(0xFFB0D4E0), Color(0xFF5A9AB0)],
    <Color>[Color(0xFFCDAA8C), Color(0xFF8B6250)],
    <Color>[Color(0xFF4AA8D8), Color(0xFF1E5C8A)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _palettes[(tenant.imageSeed - 1) % _palettes.length];
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(Icons.person, color: AppColors.onInk, size: 28),
        ),
        Positioned(
          bottom: -4,
          left: -4,
          child: _MatchPill(percent: tenant.matchPercent, color: tenant.matchDotColor),
        ),
      ],
    );
  }
}

class _MatchPill extends StatelessWidget {
  const _MatchPill({required this.percent, required this.color});

  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 3),
          Text(
            '$percent%',
            style: TextStyle(
              color: AppColors.onInk,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantInfo extends StatelessWidget {
  const _TenantInfo({required this.tenant});

  final Tenant tenant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              tenant.name,
              style: AppTextStyles.label(context).copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (tenant.isVerified) ...<Widget>[
              SizedBox(width: 4),
              Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 15),
            ],
          ],
        ),
        SizedBox(height: 2),
        Text(
          '${tenant.occupation} Â· ${tenant.incomeRange}',
          style: AppTextStyles.caption(context).copyWith(fontSize: 12),
        ),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: tenant.tags
              .map((tag) => _TagChip(label: tag))
              .toList(),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: context.appColors.fieldBorder),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: context.appColors.textPrimary,
        ),
      ),
    );
  }
}
