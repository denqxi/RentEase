import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Shared dark-ink header band used across all admin pages — gives the admin
/// panel a distinct "control room" identity while reusing app color tokens.
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.bottom,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Optional widget at the right edge of the title row (e.g. avatar menu).
  final Widget? trailing;

  /// Optional widget rendered below the title row (e.g. search field).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appColors.ink,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppColors.onInk,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12.5,
                              color: context.appColors.indicatorInactive,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (bottom != null) ...[
                SizedBox(height: AppSpacing.md),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Search field styled for the dark admin header.
class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 14,
        color: AppColors.onInk,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14,
          color: context.appColors.indicatorInactive,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: context.appColors.indicatorInactive,
          size: 18,
        ),
        filled: true,
        fillColor: AppColors.onInk.withValues(alpha: 0.10),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(
            color: AppColors.onInk.withValues(alpha: 0.14),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}

/// Admin avatar with a popup menu — used as the header trailing widget on the
/// dashboard for logging out (admin has no profile tab).
class AdminAvatarMenu extends StatelessWidget {
  const AdminAvatarMenu({required this.onLogout, super.key});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      color: context.appColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) {
        if (v == 'logout') onLogout();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 16, color: AppColors.destructive),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Log out',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.onInk.withValues(alpha: 0.25),
          ),
        ),
        child: Center(
          child: Text(
            'A',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.onInk,
            ),
          ),
        ),
      ),
    );
  }
}
