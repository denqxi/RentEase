import '../../../core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/activity_cubit.dart';
import '../model/activity_item.dart';
import '../services/notification_router.dart';

/// A simplified, Facebook-style notification item tile.
///
/// Features clean single-row layout, visual read/unread indicators
/// (blue dot + tint + bold), and role-strict tap navigation.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.item,
    required this.isOwner,
    super.key,
  });

  final ActivityItem item;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;

    // Pick icon and colors based on notification rawType / type
    final (icon, iconColor, bgColor) = _iconConfig(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.accentSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnread ? AppColors.accentSoft : AppColors.fieldBorder,
          width: isUnread ? 1.0 : 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            if (isUnread) {
              await context.read<ActivityCubit>().markItemRead(item.id);
            }
            if (context.mounted) {
              await NotificationRouter.navigate(
                context: context,
                item: item,
                isOwner: isOwner,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Type Icon Badge ──
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Title, Body, Timestamp ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13.5,
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      if (item.body != null &&
                          item.body!.isNotEmpty &&
                          item.body != item.title) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.body!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        item.timeAgo,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                          color: isUnread
                              ? AppColors.primary
                              : AppColors.hint,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Unread Dot Indicator ──
                if (isUnread) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _iconConfig(ActivityItem item) {
    final raw = item.rawType ?? '';
    if (raw == 'rating' || item.type == ActivityType.rating) {
      return (
        Icons.star_rounded,
        AppColors.matchMedium,
        AppColors.amberFill,
      );
    }
    if (raw.contains('invitation')) {
      return (
        Icons.door_front_door_outlined,
        AppColors.matchHigh,
        AppColors.greenFill,
      );
    }
    if (raw == 'message') {
      return (
        Icons.chat_bubble_outline_rounded,
        AppColors.accent,
        AppColors.accentSoft,
      );
    }
    if (raw.contains('inquiry')) {
      return (
        Icons.mail_outline_rounded,
        AppColors.primary,
        AppColors.accentSoft,
      );
    }
    return (
      Icons.notifications_none_rounded,
      AppColors.primary,
      AppColors.accentSoft,
    );
  }
}
