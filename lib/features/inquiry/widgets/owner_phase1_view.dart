import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../cubit/inquiry_thread_cubit.dart';
import '../domain/services/inquiry_service.dart';
import '../model/inquiry_summary.dart';
import 'contact_consent_notice.dart';
import 'rejected_owner_notice.dart';

/// Owner side of Phase 1: the auto-sent tenant summary (built live from the
/// tenant's user + tenantProfiles docs) and the Accept / Decline decision.
class OwnerPhase1View extends StatelessWidget {
  const OwnerPhase1View({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InquiryThreadCubit>().state;
    final inquiry = state.inquiry!;
    final tenant = state.tenant;
    final profile = state.tenantProfile;
    final moveIn = profile?.moveInDate?.toDate();
    final pending = InquiryService.isPhase1Pending(inquiry);

    String orDash(String? v) => (v == null || v.trim().isEmpty) ? '—' : v;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            children: [
              // Status banner card matching Phase 2 style
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.fieldBorder.withValues(alpha: 0.75),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.fieldBorder),
                      ),
                      child: const Icon(
                        Icons.mark_chat_unread_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pending
                                ? 'New inquiry received — review tenant profile.'
                                : (inquiry.status == 'closed'
                                      ? 'Inquiry closed.'
                                      : 'You declined this inquiry.'),
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pending
                                ? 'Accepting this inquiry unlocks open chat.'
                                : 'Chat remains locked for this thread.',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Icon(
                    Icons.smart_toy_outlined,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Tenant summary from RentEase',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryRow(
                      'Name',
                      fullNameOf(
                        tenant,
                        fallback: 'Tenant',
                        loaded: !state.isLoading,
                      ),
                    ),
                    _SummaryRow('Gender', orDash(tenant?.gender)),
                    _SummaryRow('School', orDash(profile?.school)),
                    _SummaryRow('Occupation', orDash(profile?.occupation)),
                    _SummaryRow(
                      'Move-in date',
                      moveIn == null
                          ? '—'
                          : '${moveIn.year}-${moveIn.month.toString().padLeft(2, '0')}-${moveIn.day.toString().padLeft(2, '0')}',
                    ),
                    _SummaryRow(
                      'Group size',
                      '${profile?.groupSize ?? 1} person(s)',
                    ),
                    _SummaryRow(
                      'Budget',
                      profile == null ? '—' : '₱${profile.maxBudget}/mo',
                    ),
                    _SummaryRow(
                      'Smoker',
                      profile?.isSmoker == true ? 'Yes' : 'No',
                    ),
                    _SummaryRow(
                      'Has pet',
                      profile?.hasPet == true ? 'Yes' : 'No',
                    ),
                    const SizedBox(height: 10),
                    // An inquiry can only be created against a bScore = 1
                    // match (enforced by firestore.rules), so every tenant
                    // reaching this screen passed all of the owner's rules.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.matchHigh.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.matchHigh,
                          width: 0.6,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.matchHigh,
                            size: 13,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Passes all your rules',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.matchHigh,
                            ),
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
        if (state.isCounterpartDeleted(isOwner: true))
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Center(
                child: Text(
                  'This user is not available.',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.slate500,
                  ),
                ),
              ),
            ),
          )
        else if (state.ownerRejected && pending)
          const RejectedOwnerNotice(isOwner: true)
        else
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SafeArea(
              top: false,
              child: pending
                  ? Column(
                      children: [
                        const ContactConsentNotice(sharedWith: 'the tenant'),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: state.isBusy ? 'Please wait...' : 'Accept',
                          onPressed: state.isBusy
                              ? null
                              : () =>
                                    context.read<InquiryThreadCubit>().accept(),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: 'Decline',
                          variant: AppButtonVariant.destructiveOutline,
                          onPressed: state.isBusy
                              ? null
                              : () => _showDeclineDialog(context),
                        ),
                      ],
                    )
                  : Text(
                      inquiry.status == 'closed'
                          ? 'Closed — you marked this listing fully booked.'
                          : 'You declined this inquiry.',
                      style: AppTextStyles.body(context),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
      ],
    );
  }

  Future<void> _showDeclineDialog(BuildContext context) async {
    final cubit = context.read<InquiryThreadCubit>();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _DeclineInquiryDialog(),
    );
    if (reason != null) await cubit.decline(reason);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _DeclineInquiryDialog extends StatefulWidget {
  const _DeclineInquiryDialog();

  @override
  State<_DeclineInquiryDialog> createState() => _DeclineInquiryDialogState();
}

class _DeclineInquiryDialogState extends State<_DeclineInquiryDialog> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Decline inquiry',
        style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Provide a reason for declining (optional):',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                filled: true,
                fillColor: context.appColors.fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.field),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: context.appColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_reasonController.text),
          child: const Text(
            'Confirm',
            style: TextStyle(
              color: AppColors.destructive,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
