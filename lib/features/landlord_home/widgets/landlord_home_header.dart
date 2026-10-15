import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../activity/view/activity_screen.dart';

/// Top header for the Owner / Landlord Home screen.
///
/// Features a rounded-edge white container with subtle drop shadow,
/// profile avatar with cyan ring and online dot, greeting + owner name with sparkle,
/// and a circular notification bell button with a subtle colored badge circle.
class LandlordHomeHeader extends StatelessWidget {
  const LandlordHomeHeader({
    required this.userName,
    this.photoUrl,
    this.isVerified = false,
    this.hasUnreadNotifications = false,
    this.hasUnreadInquiries = false,
    this.showNotificationDot = true,
    this.onNotificationTap,
    this.now,
    super.key,
  });

  final String userName;
  final String? photoUrl;
  final bool isVerified;
  final bool hasUnreadNotifications;
  final bool hasUnreadInquiries;
  final bool showNotificationDot;
  final VoidCallback? onNotificationTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final localNow = now ?? DateTime.now();
    final greeting = greetingFor(localNow);

    final displayName = userName.trim().isEmpty ? 'Owner' : userName.trim();
    final hasBadge =
        hasUnreadNotifications || hasUnreadInquiries || showNotificationDot;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF1F5F9),
            width: 1.2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            // Profile avatar with soft cyan ring and online status indicator
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE0F2FE),
                    border: Border.all(
                      color: const Color(0xFFBAE6FD).withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(2.0),
                  child: ClipOval(
                    child: photoUrl != null && photoUrl!.trim().isNotEmpty
                        ? Image.network(
                            photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _defaultAvatar(),
                          )
                        : _defaultAvatar(),
                  ),
                ),
                // Green online status dot
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Greeting & Name column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '$greeting,',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                      height: 1.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isVerified)
                        const AppSvgIcon(
                          svgString: AppSvgIcons.verifiedBadge,
                          size: 15,
                        )
                      else
                        const Text(
                          '✨',
                          style: TextStyle(fontSize: 13),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Notification bell with subtle background circle and colored dot
            Semantics(
              button: true,
              label: 'Notifications',
              child: GestureDetector(
                onTap: () {
                  if (onNotificationTap != null) {
                    onNotificationTap!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ActivityScreen(),
                      ),
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(
                      color: const Color(0xFFF1F5F9),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.notifications_none_rounded,
                        size: 20,
                        color: Color(0xFF334155),
                      ),
                      if (hasBadge)
                        Positioned(
                          top: 1,
                          right: 2,
                          child: Container(
                            width: 7.5,
                            height: 7.5,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF87171),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Image.asset(
      'assets/images/owner.png',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(
        Icons.person_rounded,
        size: 22,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}
