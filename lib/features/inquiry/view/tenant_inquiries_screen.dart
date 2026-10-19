import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../activity/cubit/activity_cubit.dart';
import '../../auth/presentation/current_uid.dart';
import '../cubit/inquiry_list_cubit.dart';
import '../data/repositories/inquiry_repository_impl.dart';
import '../domain/services/inquiry_service.dart';
import '../model/inquiry_summary.dart';
import 'inquiry_thread_screen.dart';

/// Tenant inbox — the tenant's own inquiries, live from Firestore.
class TenantInquiriesScreen extends StatelessWidget {
  const TenantInquiriesScreen({this.showBackButton = true, super.key});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final uid = currentUidOrNull(context);
    if (uid == null) {
      // Guests never reach this tab (MainShell gates it), and the offline
      // screenshot harness has no signed-in user.
      return const _InboxMessage('Sign in to see your inquiries.');
    }
    return BlocProvider(
      create: (_) => InquiryListCubit(
        uid: uid,
        isOwner: false,
        repository: InquiryRepositoryImpl(),
      ),
      child: _TenantInquiriesView(showBackButton: showBackButton),
    );
  }
}

class _TenantInquiriesView extends StatefulWidget {
  const _TenantInquiriesView({this.showBackButton = true});

  final bool showBackButton;

  @override
  State<_TenantInquiriesView> createState() => _TenantInquiriesViewState();
}

class _TenantInquiriesViewState extends State<_TenantInquiriesView> {
  int _selectedTab = 0; // 0 = Active, 1 = Resolved

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InquiryListCubit>().state;
    final activityState = context.watch<ActivityCubit?>()?.state;
    final unreadInquiryIds = activityState?.unreadInquiryIds ?? const <String>{};
    final int unreadCount = unreadInquiryIds.length;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: Stack(
        children: <Widget>[
          // Subtle top-left gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 195,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.05,
                    colors: <Color>[
                      const Color(0xFFCCF2FE).withValues(alpha: 0.70),
                      const Color(0xFFE0F7FE).withValues(alpha: 0.35),
                      const Color(0xFFE0F7FE).withValues(alpha: 0.0),
                    ],
                    stops: const <double>[0.0, 0.45, 0.88],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (widget.showBackButton && Navigator.of(context).canPop()) ...[
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.appColors.fieldFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inquiries',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: context.appColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track and manage your property conversations',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.appColors.textSecondary,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 12),
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A8F0),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _SegmentedControl(
                selected: _selectedTab,
                hasActiveDot: state.active.any(
                  (s) => unreadInquiryIds.contains(s.inquiry.inquiryId),
                ),
                hasResolvedDot: state.resolved.any(
                  (s) => unreadInquiryIds.contains(s.inquiry.inquiryId),
                ),
                onChanged: (i) => setState(() => _selectedTab = i),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.errorMessage != null && state.items.isEmpty
                  ? _InboxMessage(state.errorMessage!)
                  : _InquiryList(
                      items: _selectedTab == 0 ? state.active : state.resolved,
                      unreadInquiryIds: unreadInquiryIds,
                      emptyText: _selectedTab == 0
                          ? 'No active inquiries yet. Send one from a '
                                'compatible property.'
                          : 'No resolved inquiries yet.',
                    ),
            ),
          ],
        ),
      ),
    ],
  ),
);
  }
}

class _InboxMessage extends StatelessWidget {
  const _InboxMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            color: context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _InquiryList extends StatelessWidget {
  const _InquiryList({
    required this.items,
    required this.emptyText,
    this.unreadInquiryIds = const <String>{},
  });

  final List<InquirySummary> items;
  final String emptyText;
  final Set<String> unreadInquiryIds;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _InboxMessage(emptyText);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: items.length + 1,
      itemBuilder: (ctx, i) {
        if (i == items.length) return SizedBox(height: AppSpacing.lg);
        final item = items[i];
        final inquiry = item.inquiry;
        final isUnread = unreadInquiryIds.contains(inquiry.inquiryId);

        return GestureDetector(
          onTap: () {
            try {
              context.read<ActivityCubit>().markInquiryRead(inquiry.inquiryId);
            } catch (_) {}
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => InquiryThreadScreen(
                  inquiryId: inquiry.inquiryId,
                  isOwner: false,
                ),
              ),
            );
          },
          child: _InquiryCard(
            propertyInitials: item.propertyInitials,
            propertyName: item.propertyTitle,
            ownerName: item.counterpartName,
            phase: inquiry.stage.toInt(),
            isInvitation: InquiryService.isInvite(inquiry),
            date: inquiryDateLabel(inquiry.updatedAt?.toDate()),
            isUnread: isUnread,
            resolvedStatus: switch (inquiry.status) {
              'booked' => 'Booked',
              'declined' => 'Declined',
              'closed' => 'Closed',
              _ => null,
            },
          ),
        );
      },
    );
  }
}

// ── Segmented control ────────────────────────────────────────────────────────

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.selected,
    required this.onChanged,
    this.hasActiveDot = false,
    this.hasResolvedDot = false,
  });

  final int selected;
  final ValueChanged<int> onChanged;
  final bool hasActiveDot;
  final bool hasResolvedDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: <Widget>[
          _SegTab(
            label: 'Active',
            isSelected: selected == 0,
            hasDot: hasActiveDot,
            onTap: () => onChanged(0),
          ),
          _SegTab(
            label: 'Resolved',
            isSelected: selected == 1,
            hasDot: hasResolvedDot,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  const _SegTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.hasDot = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasDot;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13.5,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
                ),
              ),
              if (hasDot) ...[
                const SizedBox(width: 5),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A8F0),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared inquiry card ──────────────────────────────────────────────────────

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({
    required this.propertyInitials,
    required this.propertyName,
    required this.ownerName,
    required this.phase,
    required this.date,
    this.isInvitation = false,
    this.isUnread = false,
    this.resolvedStatus,
  });

  /// Owner-initiated: the tenant is the one who has to answer.
  final bool isInvitation;
  final bool isUnread;

  final String propertyInitials;
  final String propertyName;
  final String ownerName;
  final int phase;
  final String date;

  /// 'Booked' | 'Declined' | 'Closed' for resolved inquiries, else null.
  final String? resolvedStatus;

  bool get isResolved => resolvedStatus != null;

  @override
  Widget build(BuildContext context) {
    final bool isPhase1 = phase == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
          width: isUnread ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnread
                ? const Color(0xFF00A8F0).withValues(alpha: 0.07)
                : const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Initials Avatar
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isUnread
                  ? const Color(0xFFE0F7FE)
                  : (isResolved
                      ? const Color(0xFFEDF2F7)
                      : const Color(0xFFE0F2FE)),
              shape: BoxShape.circle,
            ),
            child: Text(
              propertyInitials,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 15,
                fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                color: isResolved
                    ? const Color(0xFF64748B)
                    : const Color(0xFF00A8F0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  propertyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ownerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12.5,
                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                    color: isUnread
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                if (isResolved)
                  Text(
                    resolvedStatus == 'Booked'
                        ? 'Tap to rate your stay'
                        : 'Completed',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  )
                else if (isInvitation)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.notifications_rounded,
                        size: 15,
                        color: Color(0xFF00A8F0),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Property available',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: const Color(0xFF00A8F0),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    isPhase1 ? 'Awaiting response' : 'Chat open',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                      color: isPhase1
                          ? AppColors.matchMedium
                          : const Color(0xFF00A8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Trailing: Date + unread dot + chevron
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (date.isNotEmpty)
                Text(
                  date,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11.5,
                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                    color: isUnread
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isUnread) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A8F0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
