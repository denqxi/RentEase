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

  /// Returns the subtle pastel background color for selected role cards.
  Color _getSelectedBackgroundColor(UserRole role) {
    switch (role) {
      case UserRole.tenant:
        return const Color(0xFFE3F4F7); // Very light cyan / light blue
      case UserRole.landlord:
        return const Color(0xFFE8EEF5); // Soft light blue (from dark blue character)
      case UserRole.guest:
        return const Color(0xFFFFF5E6); // Very light yellow / orange
    }
  }

  /// Returns a soft, matching border color for selected cards.
  Color _getSelectedBorderColor(UserRole role) {
    switch (role) {
      case UserRole.tenant:
        return const Color(0xFFBCE5EC);
      case UserRole.landlord:
        return const Color(0xFFC7D9EC);
      case UserRole.guest:
        return const Color(0xFFF7E2C4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? _getSelectedBackgroundColor(role)
        : context.appColors.surface;

    final borderColor = selected
        ? _getSelectedBorderColor(role)
        : context.appColors.fieldBorder.withOpacity(0.35);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: borderColor,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // Very subtle shadow
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                // PNG illustration enlarged to fill the circle cleanly
                ClipOval(
                  child: Image.asset(
                    role.imagePath,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        role.label,
                        style: AppTextStyles.label(context)
                            .copyWith(fontSize: 17),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(role.description, style: AppTextStyles.body(context)),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                _RadioDot(selected: selected, role: role),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected, required this.role});

  final bool selected;
  final UserRole role;

  Color _getRadioColor(UserRole role) {
    switch (role) {
      case UserRole.tenant:
        return const Color(0xFF0E8FA0);
      case UserRole.landlord:
        return const Color(0xFF2C5282);
      case UserRole.guest:
        return const Color(0xFFDD6B20);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getRadioColor(role);

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? activeColor : context.appColors.fieldBorder,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: CircleAvatar(radius: 5, backgroundColor: activeColor),
            )
          : null,
    );
  }
}
