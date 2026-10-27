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
          // Subtle top-left gradient (matching Home & Search)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.15,
                    colors: <Color>[
                      AppColors.onboardingSky.withValues(alpha: 0.75),
                      AppColors.skyFill.withValues(alpha: 0.40),
                      AppColors.skyFill.withValues(alpha: 0.0),
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
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.surface,
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
            const SizedBox(height: AppSpacing.md),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: AppColors.skyFill,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 24,
                  color: AppColors.blue600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No Inquiries',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: context.appColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
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
        if (i == items.length) return const SizedBox(height: AppSpacing.lg);
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
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.slate200.withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(3.5),
      child: Row(
        children: <Widget>[
          _SegTab(
            label: 'Inquiries',
            isSelected: selected == 0,
            hasDot: hasActiveDot,
            onTap: () => onChanged(0),
          ),
          _SegTab(
            label: 'History',
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
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : AppColors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppColors.slate900.withValues(alpha: 0.05),
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
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              if (hasDot) ...[
                const SizedBox(width: 5),
                Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
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
  final int phase;
  final String date;

  /// 'Booked' | 'Declined' | 'Closed' for resolved inquiries, else null.
  final String? resolvedStatus;

  bool get isResolved => resolvedStatus != null;

  @override
  Widget build(BuildContext context) {
    final bool isPhase1 = phase == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.40)
              : AppColors.slate200.withValues(alpha: 0.8),
          width: isUnread ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.slate900.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // 1. Clean Initials Avatar
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isUnread
                  ? AppColors.skyFill
                  : (isResolved ? AppColors.fieldFill : AppColors.tenantFillBlue),
              shape: BoxShape.circle,
            ),
            child: Text(
              propertyInitials,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14.5,
                fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                color: isResolved
                    ? AppColors.slate500
                    : (isUnread ? AppColors.blue600 : AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 13),

          // 2. Main Content: Property Name & Status Badge (Arrow, CI and Match removed)
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
                    fontSize: 14.5,
                    fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                    color: AppColors.slate900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                _buildStatusBadge(
                  isResolved: isResolved,
                  resolvedStatus: resolvedStatus,
                  isInvitation: isInvitation,
                  isPhase1: isPhase1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // 3. Trailing: Date & Unread indicator (Arrow removed)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (date.isNotEmpty)
                Text(
                  date,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11.5,
                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                    color: isUnread ? AppColors.primary : AppColors.slate400,
                  ),
                ),
              if (isUnread) ...[
                const SizedBox(height: 6),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool isResolved,
    required String? resolvedStatus,
    required bool isInvitation,
    required bool isPhase1,
  }) {
    // Unbadged, clean colored text and non-bold with icon for Awaiting response
    if (!isResolved && !isInvitation && isPhase1) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 13,
            color: AppColors.amberPrimary,
          ),
          SizedBox(width: 4),
          Text(
            'Awaiting response',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.amberPrimary,
            ),
          ),
        ],
      );
    }

    final String label;
    final Color bg;
    final Color textColor;
    final Color borderColor;
    final IconData icon;

    // Unbadged, clean colored text and non-bold with icon for Booked in History
    if (isResolved && resolvedStatus == 'Booked') {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 13,
            color: AppColors.green700,
          ),
          SizedBox(width: 4),
          Text(
            'Booked',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.green700,
            ),
          ),
        ],
      );
    }

    if (isResolved) {
      if (resolvedStatus == 'Declined') {
        label = 'Declined';
        bg = AppColors.fieldFill;
        textColor = AppColors.slate500;
        borderColor = AppColors.slate200;
        icon = Icons.cancel_outlined;
      } else {
        label = 'Closed';
        bg = AppColors.fieldFill;
        textColor = AppColors.slate500;
        borderColor = AppColors.slate200;
        icon = Icons.archive_outlined;
      }
    } else if (isInvitation) {
      label = 'Invitation';
      bg = AppColors.skyFill;
      textColor = AppColors.blue600;
      borderColor = AppColors.sky200;
      icon = Icons.mail_outline_rounded;
    } else {
      label = 'Chat open';
      bg = AppColors.emerald50;
      textColor = AppColors.emerald600;
      borderColor = AppColors.emerald400.withValues(alpha: 0.4);
      icon = Icons.chat_bubble_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: textColor),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
