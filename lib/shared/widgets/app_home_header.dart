import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/date_utils.dart';
import 'app_svg_icon.dart';

/// Top header for Home screens (shared across Tenant and Landlord/Owner).
///
/// Features:
/// - Left: Floating pure white pill with soft drop shadow enclosing a gradient-ringed
///   avatar with online indicator, dynamic time-based greeting, user name, and verified/sparkle badge.
/// - Right: Circular white action buttons for theme (moon) and inquiries (message) with notification badge.
/// - Adaptive inquiry routing: Landlord redirects to owner inquiries; Tenant redirects to tenant inquiries.
class AppHomeHeader extends StatelessWidget {
  const AppHomeHeader({
    required this.userName,
    this.photoUrl,
    this.isVerified = false,
    this.isOwner = false,
    this.isGuest = false,
    this.hasUnreadInquiries = false,
    this.onInquiryTap,
    this.now,
    super.key,
  });

  final String userName;
  final String? photoUrl;
  final bool isVerified;
  final bool isOwner;
  final bool isGuest;
  final bool hasUnreadInquiries;
  final VoidCallback? onInquiryTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final localNow = now ?? DateTime.now();
    final greeting = greetingFor(localNow);

    final fallback = isGuest ? 'Guest' : (isOwner ? 'Owner' : 'Tenant');
    final displayName = userName.trim().isEmpty ? fallback : userName.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // Floating white pill: avatar + greeting + name + badge (height 48 to align with right buttons)
          Flexible(
            child: Container(
              height: 48,
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
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
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Profile avatar with gradient ring and online indicator
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
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
                  const SizedBox(width: 8),
                  // Greeting & Name column
                  Flexible(
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
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Right action buttons: Moon + Message
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Moon button (theme toggle placeholder)
              Semantics(
                button: true,
                label: 'Theme mode',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                      width: 1,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: AppSvgIcon(
                      svgString: AppSvgIcons.moon,
                      size: 19,
                      color: Color(0xFF1B1B1B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Message / Inquiries button
              Semantics(
                button: true,
                label: 'Manage inquiries',
                child: GestureDetector(
                  onTap: () {
                    if (onInquiryTap != null) {
                      onInquiryTap!();
                    } else if (isOwner) {
                      Navigator.of(context).pushNamed(AppRouter.ownerInquiries);
                    } else {
                      Navigator.of(context).pushNamed(AppRouter.tenantInquiries);
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                        width: 1,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        const AppSvgIcon(
                          svgString: AppSvgIcons.inquiry,
                          size: 19,
                          color: Color(0xFF1B1B1B),
                        ),
                        if (hasUnreadInquiries)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              width: 8,
                              height: 8,
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
        ],
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
