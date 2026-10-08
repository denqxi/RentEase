import 'package:flutter/material.dart';

import '../../../shared/widgets/app_home_header.dart';

/// Top header for the Owner / Landlord Home screen.
///
/// Reuses the shared [AppHomeHeader] with `isOwner: true` to avoid duplicate code.
class LandlordHomeHeader extends StatelessWidget {
  const LandlordHomeHeader({
    required this.userName,
    this.photoUrl,
    this.isVerified = false,
    this.hasUnreadInquiries = true,
    this.now,
    super.key,
  });

  final String userName;
  final String? photoUrl;
  final bool isVerified;
  final bool hasUnreadInquiries;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return AppHomeHeader(
      userName: userName,
      photoUrl: photoUrl,
      isVerified: isVerified,
      isOwner: true,
      hasUnreadInquiries: hasUnreadInquiries,
      now: now,
    );
  }
}
