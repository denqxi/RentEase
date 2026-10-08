import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/phase_badge.dart';
import '../../auth/presentation/current_uid.dart';
import '../cubit/inquiry_list_cubit.dart';
import '../data/repositories/inquiry_repository_impl.dart';
import '../domain/services/inquiry_service.dart';
import '../model/inquiry_summary.dart';
import 'inquiry_thread_screen.dart';

/// Tenant inbox — the tenant's own inquiries, live from Firestore.
class TenantInquiriesScreen extends StatelessWidget {
  const TenantInquiriesScreen({super.key});

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
      child: const _TenantInquiriesView(),
    );
  }
}

class _TenantInquiriesView extends StatefulWidget {
  const _TenantInquiriesView();

  @override
  State<_TenantInquiriesView> createState() => _TenantInquiriesViewState();
}

class _TenantInquiriesViewState extends State<_TenantInquiriesView> {
  int _selectedTab = 0; // 0 = Active, 1 = Resolved

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InquiryListCubit>().state;
    final int activeCount = state.active.length;

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (Navigator.of(context).canPop()) ...[
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
                  const Spacer(),
                  if (activeCount > 0)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onInk,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _SegmentedControl(
                selected: _selectedTab,
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
                      emptyText: _selectedTab == 0
                          ? 'No active inquiries yet. Send one from a '
                                'compatible property.'
                          : 'No resolved inquiries yet.',
                    ),
            ),
          ],
        ),
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
  const _InquiryList({required this.items, required this.emptyText});

  final List<InquirySummary> items;
  final String emptyText;

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
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => InquiryThreadScreen(
                inquiryId: inquiry.inquiryId,
                isOwner: false,
              ),
            ),
          ),
          child: _InquiryCard(
            propertyInitials: item.propertyInitials,
            propertyName: item.propertyTitle,
            ownerName: item.counterpartName,
            phase: inquiry.stage.toInt(),
            isInvitation: InquiryService.isInvite(inquiry),
            date: inquiryDateLabel(inquiry.updatedAt?.toDate()),
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

// â”€â”€ Segmented control â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: <Widget>[
          _SegTab(
            label: 'Active',
            isSelected: selected == 0,
            onTap: () => onChanged(0),
          ),
          _SegTab(
            label: 'Resolved',
            isSelected: selected == 1,
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
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? context.appColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppColors.scrim.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? context.appColors.textPrimary
                  : context.appColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Shared inquiry card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({
    required this.propertyInitials,
    required this.propertyName,
    required this.ownerName,
    required this.phase,
    required this.date,
    this.isInvitation = false,
    this.resolvedStatus,
  });

  /// Owner-initiated: the tenant is the one who has to answer.
  final bool isInvitation;

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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.scrim.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isResolved ? context.appColors.fieldFill : AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              propertyInitials,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isResolved
                    ? context.appColors.textSecondary
                    : AppColors.accent,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  propertyName,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  ownerName,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: context.appColors.textSecondary,
                  ),
                ),
                SizedBox(height: 3),
                if (isResolved)
                  Text(
                    resolvedStatus == 'Booked'
                        ? 'Tap to rate your stay'
                        : 'Completed',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.hint,
                    ),
                  )
                else
                  Text(
                    isPhase1
                        ? (isInvitation
                              ? 'Invitation - respond'
                              : 'Awaiting response')
                        : 'Chat open',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPhase1
                          ? AppColors.matchMedium
                          : AppColors.accent,
                    ),
                  ),
              ],
            ),
          ),
          // Trailing
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (isResolved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.fieldFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    resolvedStatus!,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.hint,
                    ),
                  ),
                )
              else
                PhaseBadge(phase: phase),
              if (date.isNotEmpty) ...<Widget>[
                SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: context.appColors.hint,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
