import 'package:flutter/material.dart';

import '../../../core/constants/app_svg_icons.dart';
import '../../../shared/widgets/app_home_header.dart';

/// Top header for the Owner / Landlord Home screen.
///
/// Features a single full-width floating capsule container with profile avatar,
/// greeting, owner name + badge on the left, and notification bell on the right.
class LandlordHomeHeader extends StatelessWidget {
  const LandlordHomeHeader({
    required this.userName,
    this.photoUrl,
    this.isVerified = false,
    this.hasUnreadNotifications = false,
    this.hasUnreadInquiries = false,
    this.onNotificationTap,
    this.now,
    super.key,
  });

  final String userName;
  final String? photoUrl;
  final bool isVerified;
  final bool hasUnreadNotifications;
  final bool hasUnreadInquiries;
  final VoidCallback? onNotificationTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return AppHomeHeader(
      userName: userName,
      photoUrl: photoUrl,
      isVerified: isVerified,
      isOwner: true,
      actionSvgString: AppSvgIcons.notification,
      actionLabel: 'Notifications',
      hasUnread: hasUnreadNotifications || hasUnreadInquiries,
      onActionTap: onNotificationTap,
      now: now,
    );
  }
}
