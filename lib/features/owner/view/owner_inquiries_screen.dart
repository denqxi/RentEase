import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/phase_badge.dart';
import '../../auth/presentation/current_uid.dart';
import '../../inquiry/cubit/inquiry_list_cubit.dart';
import '../../inquiry/data/repositories/inquiry_repository_impl.dart';
import '../../inquiry/model/inquiry_summary.dart';
import '../../inquiry/view/inquiry_thread_screen.dart';

/// Owner inbox — inquiries tenants sent to this owner's properties, live.
/// Sorted by latest activity; owner-side discovery is filtering-only
/// (CLAUDE.md), so tenants carry no ranking score here.
class OwnerInquiriesScreen extends StatelessWidget {
  const OwnerInquiriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = currentUidOrNull(context);
    final body = uid == null
        ? const _InboxMessage('Sign in to see your inquiries.')
        : BlocProvider(
            create: (_) => InquiryListCubit(
              uid: uid,
              isOwner: true,
              repository: InquiryRepositoryImpl(),
            ),
            child: const _OwnerInquiryTabs(),
          );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.appColors.surface,
        appBar: AppBar(
          backgroundColor: context.appColors.surface,
          elevation: 0,
          title: Text(
            'Inquiries',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: context.appColors.textSecondary,
            tabs: const [
              Tab(text: 'Incoming'),
              Tab(text: 'Sent'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: body,
      ),
    );
  }
}

class _OwnerInquiryTabs extends StatelessWidget {
  const _OwnerInquiryTabs();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InquiryListCubit>().state;
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return _InboxMessage(state.errorMessage!);
    }
    return TabBarView(
      children: [
        _InquiryList(
          items: state.active,
          emptyText: 'No incoming inquiries yet.',
        ),
        // Owner-initiated invitations ("Invite" on Find Tenants) aren't
        // built yet — every inquiry today is tenant-initiated.
        const _InboxMessage('No sent invitations yet.'),
        _InquiryList(items: state.resolved, emptyText: 'No past inquiries yet.'),
      ],
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
          style: AppTextStyles.body(context),
          textAlign: TextAlign.center,
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
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _OwnerInquiryCard(summary: items[i]),
    );
  }
}

class _OwnerInquiryCard extends StatelessWidget {
  const _OwnerInquiryCard({required this.summary});

  final InquirySummary summary;

  @override
  Widget build(BuildContext context) {
    final inquiry = summary.inquiry;
    final phase = inquiry.stage.toInt();
    final resolvedLabel = switch (inquiry.status) {
      'booked' => 'Booked',
      'declined' => 'Declined',
      'closed' => 'Closed',
      _ => null,
    };
    final statusColor = switch (inquiry.status) {
      'booked' => AppColors.accent,
      'declined' => AppColors.destructive,
      _ => context.appColors.textSecondary,
    };

    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            InquiryThreadScreen(inquiryId: inquiry.inquiryId, isOwner: true),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.accentSoft,
                child: Text(
                  summary.counterpartInitials,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.ink,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.counterpartName,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${summary.propertyTitle} · '
                      '${inquiryDateLabel(inquiry.updatedAt?.toDate())}',
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              if (resolvedLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    resolvedLabel,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                )
              else
                PhaseBadge(phase: phase),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          if (resolvedLabel != null)
            _LinkButton(
              label: inquiry.status == 'booked' ? 'View & rate' : 'View',
              onTap: open,
            )
          else if (phase == 1)
            AppButton(label: 'Review inquiry', isSmall: true, onPressed: open)
          else
            _LinkButton(label: 'Open chat', onTap: open),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
