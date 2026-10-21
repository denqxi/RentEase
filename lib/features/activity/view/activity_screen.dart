import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../profile/cubit/profile_cubit.dart';
import '../../registration/model/user_role.dart';
import '../cubit/activity_cubit.dart';
import '../widgets/notification_tile.dart';

/// Simplified Facebook-style Notifications screen.
///
/// Features:
/// - Clean header with title and working "Mark all as read" button.
/// - Removed confusing subheaders.
/// - Simple All / Unread toggle.
/// - Clean single-row notification tiles with prominent read/unread indicators.
/// - Role-strict tap navigation.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({this.isOwner, super.key});

  final bool? isOwner;

  static Future<void> open(BuildContext context, {bool? isOwner}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActivityScreen(isOwner: isOwner),
      ),
    );
  }

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _filterUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.isOwner ??
        (context.watch<ProfileCubit?>()?.state.userRole == UserRole.landlord);
    final state = context.watch<ActivityCubit>().state;
    final cubit = context.read<ActivityCubit>();
    final allItems = state.items;

    final unreadCount = allItems.where((i) => !i.isRead).length;
    final displayedItems = _filterUnreadOnly
        ? allItems.where((i) => !i.isRead).toList()
        : allItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── 1. Top Header Bar ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: Colors.white,
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
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 19,
                              color: Color(0xFF0F172A),
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
                            color: Color(0xFF0F172A),
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
                                ? const Color(0xFFF0F9FF)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Mark all as read',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: unreadCount > 0
                                  ? const Color(0xFF00A8F0)
                                  : const Color(0xFF94A3B8),
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
                        label: 'All (${allItems.length})',
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
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // ── 3. Notification List or Empty State ──
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF00A8F0),
                      ),
                    )
                  : displayedItems.isEmpty
                      ? _buildEmptyState(_filterUnreadOnly)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: displayedItems.length,
                          itemBuilder: (context, index) {
                            final item = displayedItems[index];
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
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
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
                  color: Color(0xFF00A8F0),
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
                color: isSelected ? Colors.white : const Color(0xFF64748B),
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
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              filterUnread ? 'No unread notifications' : 'No notifications yet',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
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
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
