import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/date_utils.dart';
import '../../features/activity/view/activity_screen.dart';
import 'app_svg_icon.dart';

/// Top header for Home screens (shared across Tenant and Landlord/Owner).
///
/// Features:
/// - One full-width floating container capsule enclosing:
///   - Left: Profile avatar with gradient ring, online indicator, greeting, and user name + badge.
///   - Right: Action icon button (Notification bell for Owner, Inquiry message for Tenant) with unread badge.
/// - The moon icon has been removed from the top bar.
class AppHomeHeader extends StatelessWidget {
  const AppHomeHeader({
    required this.userName,
    this.photoUrl,
    this.isVerified = false,
    this.isOwner = false,
    this.isGuest = false,
    this.actionSvgString,
    this.actionLabel,
    this.hasUnread = false,
    this.onActionTap,
    this.now,
    super.key,
  });

  final String userName;
  final String? photoUrl;
  final bool isVerified;
  final bool isOwner;
  final bool isGuest;
  final String? actionSvgString;
  final String? actionLabel;
  final bool hasUnread;
  final VoidCallback? onActionTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final localNow = now ?? DateTime.now();
    final greeting = greetingFor(localNow);

    final fallback = isGuest ? 'Guest' : (isOwner ? 'Owner' : 'Tenant');
    final displayName = userName.trim().isEmpty ? fallback : userName.trim();

    final effectiveActionSvg = actionSvgString ??
        (isOwner ? AppSvgIcons.notification : AppSvgIcons.inquiry);
    final effectiveActionLabel = actionLabel ??
        (effectiveActionSvg == AppSvgIcons.notification
            ? 'Notifications'
            : 'Inquiries');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        height: 52,
        padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            // Profile avatar with gradient ring and online indicator
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color(0xFF2563EB), // Blue
                        Color(0xFF38BDF8), // Light Blue
                        Color(0xFF34D399), // Subtle Green
                      ],
                      stops: <double>[0.0, 0.50, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.all(2.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(1.5),
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
                ),
                // Green online status dot
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
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
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                      height: 1.0,
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
                            fontWeight: FontWeight.w800,
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
                        const AppSvgIcon(
                          svgString: AppSvgIcons.sparkleBadge,
                          size: 15,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right action icon (e.g. notification bell or inquiry message)
            Semantics(
              button: true,
              label: effectiveActionLabel,
              child: GestureDetector(
                onTap: () {
                  if (onActionTap != null) {
                    onActionTap!();
                  } else if (effectiveActionSvg == AppSvgIcons.notification) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ActivityScreen(),
                      ),
                    );
                  } else if (isOwner) {
                    Navigator.of(context).pushNamed(AppRouter.ownerInquiries);
                  } else {
                    Navigator.of(context).pushNamed(AppRouter.tenantInquiries);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      AppSvgIcon(
                        svgString: effectiveActionSvg,
                        size: 21,
                        color: const Color(0xFF1B1B1B),
                      ),
                      if (hasUnread)
                        Positioned(
                          top: -1,
                          right: -1,
                          child: Container(
                            width: 8.5,
                            height: 8.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF43F5E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
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
    final assetPath = isGuest
        ? 'assets/images/guest.png'
        : (isOwner ? 'assets/images/owner.png' : 'assets/images/tenant.png');
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(
        Icons.person_rounded,
        size: 22,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}
