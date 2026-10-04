import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/services/inquiry_service.dart';

/// Replaces the chat input and Accept / Decline controls in a thread whose
/// owner's verification was rejected (firestore.rules `ownerNotRejected`).
/// The owner sees a clear warning; the tenant a neutral note.
class RejectedOwnerNotice extends StatelessWidget {
  const RejectedOwnerNotice({required this.isOwner, super.key});

  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final color = isOwner ? AppColors.destructive : context.appColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isOwner
                ? AppColors.destructive.withValues(alpha: 0.08)
                : context.appColors.fieldFill,
            borderRadius: BorderRadius.circular(AppRadii.field),
            border: Border.all(
              color: isOwner ? AppColors.destructive : context.appColors.fieldBorder,
              width: 0.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isOwner ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isOwner
                      ? InquiryService.rejectedOwnerMessage
                      : InquiryService.rejectedOwnerTenantNote,
                  style: AppTextStyles.caption(context).copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
