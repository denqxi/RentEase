import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../cubit/inquiry_thread_cubit.dart';
import '../domain/services/inquiry_service.dart';
import '../model/inquiry_summary.dart';

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
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy_outlined, color: AppColors.accent, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Tenant summary from RentEase',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadii.field),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryRow('Name', fullNameOf(tenant, fallback: 'Tenant')),
                    _SummaryRow('Gender', orDash(tenant?.gender)),
                    _SummaryRow('Phone', orDash(tenant?.phone)),
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
                    _SummaryRow('Smoker', profile?.isSmoker == true ? 'Yes' : 'No'),
                    _SummaryRow('Has pet', profile?.hasPet == true ? 'Yes' : 'No'),
                    _SummaryRow(
                      'Emergency contact',
                      orDash(profile?.emergencyContact),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // An inquiry can only be created against a bScore = 1
                    // match (enforced by firestore.rules), so every tenant
                    // reaching this screen passed all of the owner's rules.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.matchHigh.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                        border: Border.all(color: AppColors.matchHigh, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.matchHigh,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Passes all your rules',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
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
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SafeArea(
            top: false,
            child: pending
                ? Column(
                    children: [
                      AppButton(
                        label: state.isBusy ? 'Please wait...' : 'Accept',
                        onPressed: state.isBusy
                            ? null
                            : () => context.read<InquiryThreadCubit>().accept(),
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
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Decline inquiry',
          style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Provide a reason for declining (optional):',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                filled: true,
                fillColor: ctx.appColors.fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.field),
                ),
              ),
            ),
          ],
        ),
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
              'Confirm',
              style: TextStyle(
                color: AppColors.destructive,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    final reason = reasonController.text;
    reasonController.dispose();
    if (confirmed == true) await cubit.decline(reason);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: context.appColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption(context).copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
