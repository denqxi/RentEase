import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/ci_score_pill.dart';
import '../../../shared/widgets/phase_badge.dart';
import 'phase1_owner_screen.dart';
import 'phase2_chat_owner_screen.dart';

class OwnerInquiriesScreen extends StatelessWidget {
  const OwnerInquiriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            tabs: [
              Tab(text: 'Incoming'),
              Tab(text: 'Sent'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _IncomingTab(),
            _SentTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _IncomingTab extends StatefulWidget {
  @override
  State<_IncomingTab> createState() => _IncomingTabState();
}

class _IncomingTabState extends State<_IncomingTab> {
  void _decline(Map<String, dynamic> inquiry) {
    setState(() {
      MockData.ownerInquiries.remove(inquiry);
      MockData.ownerInquiryHistory.insert(0, {
        'tenantName': inquiry['tenantName'],
        'tenantInitials': inquiry['tenantInitials'],
        'propertyName': inquiry['propertyName'],
        'status': 'Declined',
        'date': 'Jul 2, 2026',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...MockData.ownerInquiries]
      ..sort((a, b) => (b['ciScore'] as double).compareTo(a['ciScore'] as double));

    if (sorted.isEmpty) {
      return Center(
        child: Text('No incoming inquiries.', style: AppTextStyles.body(context)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
      itemBuilder: (ctx, i) => _OwnerInquiryCard(
        inquiry: sorted[i],
        onDecline: () => _decline(sorted[i]),
        // Re-read MockData after Accept flips the phase or a chat books it.
        onReturned: () => setState(() {}),
      ),
    );
  }
}

class _SentTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('No sent invitations yet.', style: AppTextStyles.body(context)),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  Color _statusColor(BuildContext context, String status) => switch (status) {
        'Booked' => AppColors.accent,
        'Accepted' => AppColors.matchHigh,
        'Declined' => AppColors.destructive,
        _ => context.appColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final history = MockData.ownerInquiryHistory;

    if (history.isEmpty) {
      return Center(
        child: Text('No past inquiries yet.', style: AppTextStyles.body(context)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: history.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
      itemBuilder: (ctx, i) {
        final entry = history[i];
        final status = entry['status'] as String;
        final color = _statusColor(context, status);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.accentSoft,
                child: Text(
                  entry['tenantInitials'] as String,
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
                      entry['tenantName'] as String,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${entry['propertyName']} · ${entry['date']}',
                      style: AppTextStyles.caption(context),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OwnerInquiryCard extends StatelessWidget {
  const _OwnerInquiryCard({
    required this.inquiry,
    required this.onDecline,
    required this.onReturned,
  });

  final Map<String, dynamic> inquiry;
  final VoidCallback onDecline;
  final VoidCallback onReturned;

  @override
  Widget build(BuildContext context) {
    final int phase = inquiry['phase'] as int;

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
                  inquiry['tenantInitials'] as String,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            inquiry['tenantName'] as String,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                        ),
                        CiScorePill(
                          score: (inquiry['ciScore'] as num).toDouble(),
                          isOwner: true,
                        ),
                      ],
                    ),
                    Text(inquiry['propertyName'] as String, style: AppTextStyles.caption(context)),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              PhaseBadge(phase: phase),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          if (phase == 1)
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Accept',
                    isSmall: true,
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => Phase1OwnerScreen(inquiry: inquiry),
                        ),
                      );
                      onReturned();
                    },
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Decline',
                    variant: AppButtonVariant.destructiveOutline,
                    isSmall: true,
                    onPressed: onDecline,
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Phase2ChatOwnerScreen(inquiry: inquiry),
                    ),
                  );
                  onReturned();
                },
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  'Open chat',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
