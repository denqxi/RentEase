import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Shown to non-verified owners. Copy depends on `verificationStatus`
/// ('none' | 'pending' | 'rejected'); listings of none/pending owners are
/// already live (Oct 2026: verification is a trust signal only), while a
/// rejected owner cannot write new listings (firestore.rules).
class PendingListingBanner extends StatelessWidget {
  const PendingListingBanner({super.key, this.status});

  final String? status;

  static const String noneMessage =
      'Get the Verified badge: submit your documents for review. '
      'Your listing is already live.';

  static const String pendingMessage =
      'Verification pending — your listing is live. The "Verified" badge '
      'appears once an admin approves your documents.';

  static const String rejectedMessage =
      "Verification not approved. You can't post new listings until you "
      'resubmit - please contact support.';

  /// Kept for existing references; equals the pending copy.
  static const String message = pendingMessage;

  static String messageFor(String? status) => switch (status) {
    'none' => noneMessage,
    'rejected' => rejectedMessage,
    _ => pendingMessage,
  };

  @override
  Widget build(BuildContext context) {
    final rejected = status == 'rejected';
    final color = rejected ? AppColors.destructive : AppColors.matchMedium;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            rejected ? Icons.error_outline_rounded : Icons.hourglass_top_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(messageFor(status), style: AppTextStyles.body(context)),
          ),
        ],
      ),
    );
  }
}
