import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/firestore/models/inquiry_doc.dart';
import '../../../core/firestore/models/property_doc.dart';
import '../../../core/utils/date_utils.dart';
import '../../home/view/property_detail_screen.dart';
import '../cubit/inquiry_thread_cubit.dart';
import '../domain/services/inquiry_service.dart';
import 'rejected_owner_notice.dart';

/// Tenant side of Phase 1: the auto-sent house rules and terms (built live
/// from the property doc, not stored as messages), and the chat locked
/// until the owner accepts.
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            children: [
              // ── Property Information Card ──────────────────────────────
              _PropertyInformationCard(
                property: property,
                inquiry: inquiry,
              ),
              const SizedBox(height: 12),

              // ── Invitation or Status Card ──────────────────────────────
              if (awaitingMyAnswer) ...[
                _InvitationNotificationCard(
                  propertyTitle: property?.title ?? 'this property',
                ),
                const SizedBox(height: 14),
                const _PhonePrivacyNotice(),
                const SizedBox(height: 14),
                _ActionButtons(
                  isBusy: state.isBusy,
                  onAccept: () => context.read<InquiryThreadCubit>().accept(),
                  onDecline: () => _confirmDecline(context),
                ),
              ] else if (ownerCantReply) ...[
                const RejectedOwnerNotice(isOwner: false),
              ] else ...[
                _StatusNoticeCard(
                  ended: ended,
                  closed: closed,
                  declined: declined,
                  invite: invite,
                  declineReason: inquiry.declineReason,
                ),
                const SizedBox(height: 14),
                const _PhonePrivacyNotice(),
              ],
            ],
          ),
        ),

        // ── Locked Input Bar (Messaging unavailable) ────────────────────
        if (!ownerCantReply)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                height: 48,
                padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Transform.rotate(
                        angle: 0.5,
                        child: const Icon(
                          Icons.attach_file_rounded,
                          size: 18,
                          color: AppColors.hint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Messaging unavailable',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: AppColors.hint,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.send_rounded,
                      color: AppColors.indicatorInactive,
                      size: 20,
                    ),
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
        title: const Text('Decline notification?'),
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
}

// ── Property Information Card ────────────────────────────────────────────────

class _PropertyInformationCard extends StatelessWidget {
  const _PropertyInformationCard({
    required this.property,
    this.inquiry,
  });

  final PropertyDoc? property;
  final InquiryDoc? inquiry;

  @override
  Widget build(BuildContext context) {
    final p = property;
    final advanceText = p == null
        ? '—'
        : p.advanceMonths > 0
            ? '₱${(p.monthlyRent * p.advanceMonths).toInt()}'
            : 'None';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: p != null
            ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PropertyDetailScreen(
                      propertyId: p.propertyId,
                      initialPropertyDoc: p,
                      inquiryId: inquiry?.inquiryId,
                      initialTenantCi: (inquiry?.tenantCiSnapshot ?? 0) > 0
                          ? inquiry!.tenantCiSnapshot.toDouble()
                          : null,
                    ),
                  ),
                )
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accentSoft.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Property information',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amberFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: AppColors.matchMedium,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Awaiting response',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.matchMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p != null) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (p == null)
                const Text(
                  'This listing is no longer available.',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              else ...[
                _row(
                  'Gender policy:',
                  p.allowedGender.isNotEmpty ? p.allowedGender : 'Mixed / Any',
                ),
                _row('Curfew:', formatCurfew(p.curfewHours)),
                _row('Deposit:', '₱${p.depositAmount}'),
                _row('Advance:', advanceText),
                _row('Monthly rent:', '₱${p.monthlyRent}', isLast: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Invitation Notification Card ─────────────────────────────────────────────

class _InvitationNotificationCard extends StatelessWidget {
  const _InvitationNotificationCard({required this.propertyTitle});

  final String propertyTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentSoft.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notifications_rounded,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The owner of $propertyTitle has notified you that their property is available and matches your preferences.',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Interested? Send an inquiry to connect with the owner.',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
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

// ── Phone Privacy Notice ─────────────────────────────────────────────────────

class _PhonePrivacyNotice extends StatelessWidget {
  const _PhonePrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: 0.1,
          child: const Icon(
            Icons.phone_rounded,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Your phone number will be shared with the owner once your inquiry is accepted.',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isBusy,
    required this.onAccept,
    required this.onDecline,
  });

  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: isBusy ? null : onAccept,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.surface,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Send inquiry',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.surface,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: isBusy ? null : onDecline,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              child: const Text(
                'Not interested',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Status Notice Card (When tenant initiated or inquiry ended) ──────────────

class _StatusNoticeCard extends StatelessWidget {
  const _StatusNoticeCard({
    required this.ended,
    required this.closed,
    required this.declined,
    required this.invite,
    this.declineReason,
  });

  final bool ended;
  final bool closed;
  final bool declined;
  final bool invite;
  final String? declineReason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          Icon(
            ended ? Icons.block_rounded : Icons.access_time_rounded,
            color: ended ? AppColors.destructive : AppColors.primary,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            closed
                ? 'This listing is now fully booked'
                : declined
                    ? (invite
                        ? 'You declined this property notification'
                        : 'The owner declined this inquiry')
                    : 'Waiting for owner response...',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            closed
                ? 'You can keep browsing your other matches.'
                : declined && invite
                    ? 'You can keep browsing your other matches.'
                    : declined
                        ? (declineReason?.isNotEmpty ?? false)
                            ? 'Reason: $declineReason'
                            : 'You can keep browsing your other matches.'
                        : 'Chat unlocks after the owner accepts your inquiry.',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
