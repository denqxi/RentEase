import '../../../core/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/verified_badge.dart';
import '../cubit/inquiry_thread_cubit.dart';
import '../domain/services/inquiry_service.dart';
import 'contact_consent_notice.dart';
import 'rejected_owner_notice.dart';

/// Tenant side of Phase 1: the auto-sent house rules and terms (built live
/// from the property doc, not stored as messages), and the chat locked
/// until the owner accepts. CLAUDE.md verified-badge placement #3.
class TenantPhase1View extends StatelessWidget {
  const TenantPhase1View({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InquiryThreadCubit>().state;
    final inquiry = state.inquiry!;
    final property = state.property;
    final declined = inquiry.ownerDecision == 'declined';
    // Another tenant took the last vacancy before the owner answered.
    final closed = inquiry.status == 'closed';
    final ended = declined || closed;
    // Owner invitation: the tenant is the one who answers.
    final invite = InquiryService.isInvite(inquiry);
    final awaitingMyAnswer = invite && InquiryService.isPhase1Pending(inquiry);
    // The owner's verification was rejected: they can't reply, so no waiting
    // card and no locked chat input — just a neutral note.
    final ownerCantReply = state.ownerRejected && !ended && !awaitingMyAnswer;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Bubble(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppColors.tenantTextCyan,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Auto info from RentEase',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.tenantTextCyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (property == null)
                      _line(context, 'This listing is no longer available.')
                    else ...[
                      _line(context, 'Gender policy: ${property.allowedGender}'),
                      _line(
                        context,
                        'Curfew: ${formatCurfew(property.curfewHours)}',
                      ),
                      _line(
                        context,
                        'Deposit: ₱${property.depositAmount} · Advance: '
                        '${property.advanceMonths} '
                        '${property.advanceMonths == 1 ? 'month' : 'months'}',
                      ),
                      _line(context, 'Monthly rent: ₱${property.monthlyRent}'),
                    ],
                    const SizedBox(height: 6),
                    VerifiedBadge(isVerified: state.ownerVerified, isSmall: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Bubble(
                child: _line(
                  context,
                  invite
                      ? 'The owner invited you because you passed all of their rules '
                            'and their property fits your requirements.'
                      : 'Your profile has been sent to the owner.',
                ),
              ),
            ],
          ),
        ),
        if (awaitingMyAnswer)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                const ContactConsentNotice(sharedWith: 'the owner'),
                const SizedBox(height: 8),
                AppButton(
                  label: state.isBusy ? 'Please wait...' : 'Accept invitation',
                  onPressed: state.isBusy
                      ? null
                      : () => context.read<InquiryThreadCubit>().accept(),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Decline',
                  variant: AppButtonVariant.destructiveOutline,
                  onPressed: state.isBusy
                      ? null
                      : () => _confirmDecline(context),
                ),
              ],
            ),
          )
        else if (ownerCantReply)
          const RejectedOwnerNotice(isOwner: false)
        else
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.appColors.fieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appColors.fieldBorder),
          ),
          child: Column(
            children: [
              Icon(
                ended ? Icons.block_rounded : Icons.access_time_rounded,
                color: ended ? AppColors.destructive : context.appColors.hint,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                closed
                    ? 'This listing is now fully booked'
                    : declined
                    ? (invite
                          ? 'You declined this invitation'
                          : 'The owner declined this inquiry')
                    : 'Waiting for owner response...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                closed
                    ? 'You can keep browsing your other matches.'
                    : declined && invite
                    ? 'You can keep browsing your other matches.'
                    : declined
                    ? (inquiry.declineReason?.isNotEmpty ?? false)
                          ? 'Reason: ${inquiry.declineReason}'
                          : 'You can keep browsing your other matches.'
                    : 'Chat unlocks after the owner accepts your inquiry.',
                style: TextStyle(
                  fontSize: 12,
                  color: context.appColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Locked input — CLAUDE.md: Phase 1 chat input disabled until the
        // owner accepts.
        if (!ownerCantReply)
        IgnorePointer(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.appColors.fieldFill,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: context.appColors.fieldBorder,
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Message locked...',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.appColors.hint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.send_rounded, color: AppColors.disabled, size: 22),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDecline(BuildContext context) async {
    final cubit = context.read<InquiryThreadCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline invitation?'),
        content: const Text('The owner will be told you declined.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ctx.appColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Decline',
              style: TextStyle(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.decline(null);
  }

  Widget _line(BuildContext context, String text) => Text(
    text,
    style: TextStyle(fontSize: 13, color: context.appColors.textPrimary),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.tenantFillBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: child,
      ),
    );
  }
}
