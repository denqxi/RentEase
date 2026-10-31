import '../../../core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_update/cubit/app_update_cubit.dart';
import '../../app_update/model/app_update_info.dart';
import '../../app_update/widgets/whats_new_dialog.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../registration/model/user_role.dart';
import '../../shell/cubit/shell_cubit.dart';
import '../cubit/activity_cubit.dart';
import '../widgets/notification_tile.dart';

/// Simplified Facebook-style Notifications screen.
///
/// Features:
/// - Clean header with title and working "Mark all as read" button.
/// - In-app version update alert tile (redirects to Profile to update).
/// - Simple All / Unread toggle.
/// - Clean single-row notification tiles with prominent read/unread indicators.
/// - Role-strict tap navigation.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({this.isOwner, this.onOpenProfile, super.key});

  final bool? isOwner;
  final VoidCallback? onOpenProfile;

  static Future<dynamic> open(BuildContext context, {bool? isOwner, VoidCallback? onOpenProfile}) {
    return Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (_) => ActivityScreen(isOwner: isOwner, onOpenProfile: onOpenProfile),
      ),
    );
  }

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _filterUnreadOnly = false;

  void _navigateToProfile() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop('open_profile');
    }
    widget.onOpenProfile?.call();
    try {
      context.read<ShellCubit>().selectTab(ShellTab.profile);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.isOwner ??
        (context.watch<ProfileCubit?>()?.state.userRole == UserRole.landlord);
    final state = context.watch<ActivityCubit>().state;
    final cubit = context.read<ActivityCubit>();
    final allItems = state.items;

    // Check in-app version update status
    final updateState = context.watch<AppUpdateCubit?>()?.state;
    final hasUpdate = (updateState?.hasUpdate ?? false) && updateState?.info != null;
    final updateInfo = updateState?.info;

    // Include the update notification in counts
    final unreadCount = state.unreadCount + (hasUpdate ? 1 : 0);
    final totalCount = allItems.length + (hasUpdate ? 1 : 0);
    final displayedItems = _filterUnreadOnly ? state.unreadItems : allItems;

    return Scaffold(
      backgroundColor: AppColors.fieldFill,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── 1. Top Header Bar ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (Navigator.of(context).canPop()) ...[
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 38,
                            height: 38,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: AppColors.fieldFill,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.fieldBorder,
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 19,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                      const Expanded(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      // "Mark all read" button
                      GestureDetector(
                        onTap: unreadCount > 0 ? () => cubit.markAllRead() : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: unreadCount > 0
                                ? AppColors.accentSoft
                                : AppColors.fieldFill,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Mark all as read',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: unreadCount > 0
                                  ? AppColors.primary
                                  : AppColors.hint,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── 2. All / Unread Filter Pills ──
                  Row(
                    children: [
                      _buildPill(
                        label: 'All ($totalCount)',
                        isSelected: !_filterUnreadOnly,
                        onTap: () => setState(() => _filterUnreadOnly = false),
                      ),
                      const SizedBox(width: 8),
                      _buildPill(
                        label: 'Unread ($unreadCount)',
                        isSelected: _filterUnreadOnly,
                        hasDot: unreadCount > 0,
                        onTap: () => setState(() => _filterUnreadOnly = true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.fieldBorder),

            // ── 3. Notification List or Empty State ──
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    )
                  : (displayedItems.isEmpty && !hasUpdate)
                      ? _buildEmptyState(_filterUnreadOnly)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: displayedItems.length + (hasUpdate ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (hasUpdate && index == 0) {
                              return _buildUpdateNotificationTile(context, updateInfo!);
                            }
                            final itemIndex = hasUpdate ? index - 1 : index;
                            final item = displayedItems[itemIndex];
                            return NotificationTile(
                              item: item,
                              isOwner: isOwner,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateNotificationTile(BuildContext context, AppUpdateInfo info) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => WhatsNewDialog.show(
            context,
            info: info,
            onUpdate: _navigateToProfile,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDeep,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.system_update_rounded,
                      size: 20,
                      color: AppColors.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'New Version Available: v${info.latestVersion}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        info.hasStructuredNotes
                            ? (info.features.isNotEmpty
                                ? info.features.first
                                : info.fixes.first)
                            : (info.notes.isNotEmpty
                                ? info.notes
                                : 'A new update is available. Tap here to view details.'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDeep,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tap to update in Profile',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.surface,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: AppColors.surface,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasDot = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasDot) ...[
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.surface : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool filterUnread) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppColors.fieldFill,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: AppColors.hint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              filterUnread ? 'No unread notifications' : 'No notifications yet',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filterUnread
                  ? "You're all caught up! Switch to 'All' to review previous updates."
                  : 'Activity regarding your inquiries, messages, and reviews will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
