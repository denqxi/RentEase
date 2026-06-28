import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/activity_item.dart';

/// A single row in the activity feed.
class ActivityTile extends StatelessWidget {
  const ActivityTile({required this.item, super.key});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.field),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _IconBadge(type: item.type),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: AppTextStyles.label(context).copyWith(fontSize: 13),
                ),
                SizedBox(height: 3),
                Text(item.timeAgo, style: AppTextStyles.caption(context)),
              ],
            ),
          ),
          if (!item.isRead) ...<Widget>[
            SizedBox(width: AppSpacing.sm),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.unread,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.type});

  final ActivityType type;

  @override
  Widget build(BuildContext context) {
    final (icon, bg) = switch (type) {
      ActivityType.match => (Icons.favorite, AppColors.accent),
      ActivityType.message => (Icons.chat_bubble_outline, const Color(0xFFF59E0B)),
      ActivityType.update => (Icons.sync_rounded, AppColors.accent),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Icon(icon, color: AppColors.onInk, size: 20),
    );
  }
}
