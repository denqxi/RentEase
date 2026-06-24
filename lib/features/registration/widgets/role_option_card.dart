import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/user_role.dart';

/// Selectable card representing a [UserRole] on the "Join RentEase" screen.
class RoleOptionCard extends StatelessWidget {
  const RoleOptionCard({
    required this.role,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.fieldBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.accentSoft,
                child: Icon(role.icon, color: AppColors.accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(role.icon, size: 18, color: AppColors.accent),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          role.label,
                          style: AppTextStyles.label.copyWith(fontSize: 17),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(role.description, style: AppTextStyles.body),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _RadioDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.fieldBorder,
          width: 2,
        ),
      ),
      child: selected
          ? const Center(
              child: CircleAvatar(radius: 5, backgroundColor: AppColors.accent),
            )
          : null,
    );
  }
}
