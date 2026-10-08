import 'package:flutter/material.dart';

import '../../core/constants/app_svg_icons.dart';
import '../../core/router/app_router.dart';
import 'app_svg_icon.dart';

/// Shown to non-verified owners.
///
/// Features a light, warm card with subtle border, closable action,
/// explanatory body text, and a direct "Check status >" shortcut.
class PendingListingBanner extends StatefulWidget {
  const PendingListingBanner({
    super.key,
    this.status,
    this.onClose,
    this.onCheckStatus,
  });

  final String? status;
  final VoidCallback? onClose;
  final VoidCallback? onCheckStatus;

  static const String noneMessage =
      'Get the Verified badge: submit your documents for review. '
      'Your listing is already live.';

  static const String pendingMessage =
      'Your listings are visible to prospective renters.\n'
      'Your verified badge will activate once admin checks your submitted documents.';

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
  State<PendingListingBanner> createState() => _PendingListingBannerState();
}

class _PendingListingBannerState extends State<PendingListingBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationCtrl;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rejected = widget.status == 'rejected';

    final Color bgColor = rejected
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFFFFDF5);
    final Color borderColor = rejected
        ? const Color(0xFFFECACA)
        : const Color(0xFFFDE68A).withValues(alpha: 0.9);
    final Color accentColor = rejected
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    final Color titleColor = rejected
        ? const Color(0xFF991B1B)
        : const Color(0xFF92400E);
    final Color textColor = rejected
        ? const Color(0xFFB91C1C)
        : const Color(0xFF92400E);
    final Color linkColor = rejected
        ? const Color(0xFF7F1D1D)
        : const Color(0xFF78350F);

    final String title = rejected
        ? 'Verification not approved'
        : 'Verification in progress';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Left: Rotating Hourglass or Error Container
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: rejected
                ? Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: accentColor,
                      ),
                    ),
                  )
                : Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: RotationTransition(
                        turns: _rotationCtrl,
                        child: const AppSvgIcon(
                          svgString: AppSvgIcons.hourglass,
                          size: 15,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          // Right: Content Column (Header + Subheader + Action Link aligned together)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Header row: Title + Close Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (widget.onClose != null)
                      Semantics(
                        button: true,
                        label: 'Dismiss banner',
                        child: GestureDetector(
                          onTap: widget.onClose,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.close_rounded,
                              size: 17,
                              color: titleColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                // Body text (aligned with header title)
                Text(
                  PendingListingBanner.messageFor(widget.status),
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                    height: 1.38,
                  ),
                ),
                const SizedBox(height: 10),
                // Action link: "Check status >" (aligned with header title)
                GestureDetector(
                  onTap: widget.onCheckStatus ??
                      () {
                        Navigator.of(context).pushNamed(
                          AppRouter.verificationPending,
                        );
                      },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Check status',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: linkColor,
                          decoration: TextDecoration.underline,
                          decorationColor: linkColor,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 15,
                        color: linkColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
