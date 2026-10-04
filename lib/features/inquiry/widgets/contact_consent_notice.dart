import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/services/inquiry_service.dart';

/// "Your phone number will be shared with the owner/tenant once the
/// inquiry is accepted." — shown wherever a user is about to send or accept.
class ContactConsentNotice extends StatelessWidget {
  const ContactConsentNotice({required this.sharedWith, super.key});

  /// 'the owner' or 'the tenant'.
  final String sharedWith;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.phone_outlined, size: 16, color: AppColors.accent),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            InquiryService.contactConsentMessage(sharedWith),
            style: AppTextStyles.caption(context),
          ),
        ),
      ],
    );
  }
}
