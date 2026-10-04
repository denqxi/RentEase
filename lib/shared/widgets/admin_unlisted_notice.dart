import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/owner/domain/repositories/owner_property_repository.dart'
    show adminUnlistedMessage;

/// Amber notice shown to an owner instead of the availability controls when
/// an admin has unlisted the property.
class AdminUnlistedNotice extends StatelessWidget {
  const AdminUnlistedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.matchMedium.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.matchMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.visibility_off_outlined,
            size: 18,
            color: AppColors.matchMedium,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              adminUnlistedMessage,
              style: AppTextStyles.body(context),
            ),
          ),
        ],
      ),
    );
  }
}
