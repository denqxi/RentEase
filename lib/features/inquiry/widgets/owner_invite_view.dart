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
    final tenantName = fullNameOf(
      state.tenant,
      fallback: 'The tenant',
      loaded: !state.isLoading,
    );

    final (IconData icon, Color iconColor, String title, String detail) =
        switch (inquiry.status) {
          'declined' => (
            Icons.block_rounded,
            AppColors.destructive,
            '$tenantName declined',
            (inquiry.declineReason?.isNotEmpty ?? false)
                ? 'Reason: ${inquiry.declineReason}'
                : 'You can keep looking at other compatible tenants.',
          ),
          'closed' => (
            Icons.block_rounded,
            AppColors.destructive,
            'This inquiry is closed',
            'The listing is fully booked.',
          ),
          _ => (
            Icons.access_time_rounded,
            AppColors.primary,
            'Waiting for $tenantName to respond...',
            'Chat unlocks once $tenantName responds.',
          ),
        };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$tenantName has been notified',
                style: AppTextStyles.label(
                  context,
                ).copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                property == null
                    ? 'This listing is no longer available.'
                    : '${property.title} · ₱${property.monthlyRent}/mo',
                style: AppTextStyles.body(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.fieldBorder),
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
        if (state.isCounterpartDeleted(isOwner: true))
          const Padding(
            padding: EdgeInsets.only(top: 16),
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
          )
        else if (state.ownerRejected)
          const RejectedOwnerNotice(isOwner: true),
      ],
    );
  }
}
