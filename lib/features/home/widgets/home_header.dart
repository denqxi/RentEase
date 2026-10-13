import 'package:flutter/material.dart';

import '../../../shared/widgets/app_home_header.dart';

/// Top header for the Tenant Home screen.
///
/// Reuses the shared [AppHomeHeader] with `isOwner: false` to avoid duplicate code.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.userName,
    this.photoUrl,
    this.isVerified = false,
    this.isGuest = false,
    this.hasUnreadInquiries = false,
    this.onInquiryTap,
    this.now,
    super.key,
  });

  final String userName;
  final String? photoUrl;
  final bool isVerified;
  final bool isGuest;
  final bool hasUnreadInquiries;
  final VoidCallback? onInquiryTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return AppHomeHeader(
      userName: userName,
      photoUrl: photoUrl,
      isVerified: isVerified,
      isOwner: false,
      isGuest: isGuest,
      hasUnread: hasUnreadInquiries,
      onActionTap: onInquiryTap,
      now: now,
    );
  }
}
