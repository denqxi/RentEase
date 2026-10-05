import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/inquiry_thread_cubit.dart';
import '../model/inquiry_summary.dart';
import 'rejected_owner_notice.dart';

/// Owner side of an owner-initiated invitation while it is still in Phase 1:
/// what was sent, and the tenant's pending / declined / closed outcome. The
/// owner cannot answer their own invitation (accepting opens chat for both,
/// so it is the tenant's call — enforced by firestore.rules too).
class OwnerInviteView extends StatelessWidget {
  const OwnerInviteView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InquiryThreadCubit>().state;
    final inquiry = state.inquiry!;
    final property = state.property;
    final tenantName = fullNameOf(state.tenant,
        fallback: 'The tenant', loaded: !state.isLoading);

    final (IconData icon, Color iconColor, String title, String detail) =
        switch (inquiry.status) {
          'declined' => (
            Icons.block_rounded,
            AppColors.destructive,
            '$tenantName declined your invitation',
            (inquiry.declineReason?.isNotEmpty ?? false)
                ? 'Reason: ${inquiry.declineReason}'
                : 'You can keep looking at other compatible tenants.',
          ),
          'closed' => (
            Icons.block_rounded,
            AppColors.destructive,
            'This invitation is closed',
            'The listing is fully booked.',
          ),
          _ => (
            Icons.access_time_rounded,
            context.appColors.hint,
            'Waiting for $tenantName to respond...',
            'Chat unlocks once the tenant accepts your invitation.',
          ),
        };

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(AppRadii.field),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invitation sent to $tenantName',
                style: AppTextStyles.label(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                property == null
                    ? 'This listing is no longer available.'
                    : '${property.title} · ₱${property.monthlyRent}/mo',
                style: AppTextStyles.body(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.appColors.fieldFill,
            borderRadius: BorderRadius.circular(AppRadii.field),
            border: Border.all(color: context.appColors.fieldBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.label(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(context),
              ),
            ],
          ),
        ),
        if (state.ownerRejected) const RejectedOwnerNotice(isOwner: true),
      ],
    );
  }
}
