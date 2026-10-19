import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../model/navigation_models.dart';

/// Clean, compact bottom sheet card for route preview with balanced visual hierarchy.
/// Displays:
/// 1. Unified top card: Origin (POI) on left, chevron in middle, Destination (Property) on right.
/// 2. Metrics row: Compact duration + distance, subtitle with "via [roadName]", and Drive/Walk toggle.
/// 3. Route preview callout banner with navigation icon and Google Maps guidance prompt.
/// 4. Action buttons: Google Maps CTA button + compact close button.
class LiveNavigationBottomBar extends StatelessWidget {
  final RoutePlan? routePlan;
  final RouteProfile currentProfile;
  final ValueChanged<RouteProfile> onProfileChanged;
  final VoidCallback onExit;
  final VoidCallback onLaunchGoogleMaps;
  final String destinationName;
  final String? destinationAddress;
  final String? originName;
  final String? originAddress;
  final bool isLoadingRoute;

  const LiveNavigationBottomBar({
    required this.routePlan,
    required this.currentProfile,
    required this.onProfileChanged,
    required this.onExit,
    required this.onLaunchGoogleMaps,
    required this.destinationName,
    this.destinationAddress,
    this.originName,
    this.originAddress,
    this.isLoadingRoute = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final plan = routePlan;

    // Parse origin title and subtitle (e.g. "Holy Cross of Davao College, Davao City")
    final String resolvedOriginTitle;
    final String resolvedOriginSubtitle;
    if (originName != null && originName!.contains(',')) {
      final parts = originName!.split(',');
      resolvedOriginTitle = parts.first.trim();
      resolvedOriginSubtitle = parts.sublist(1).join(',').trim();
    } else {
      resolvedOriginTitle = originName?.isNotEmpty == true ? originName! : 'Your POI';
      resolvedOriginSubtitle = originAddress?.isNotEmpty == true ? originAddress! : 'Davao City';
    }

    final String resolvedDestTitle = destinationName;
    final String resolvedDestSubtitle = destinationAddress?.isNotEmpty == true
        ? destinationAddress!
        : 'Davao City';

    // Extract prominent road name from route plan steps for the subtitle
    String? roadName;
    if (plan != null && plan.steps.isNotEmpty) {
      for (final s in plan.steps) {
        final name = s.roadName.trim();
        if (name.isNotEmpty && !name.toLowerCase().contains('direct route')) {
          roadName = name;
          break;
        }
      }
    }

    final modeLabel = currentProfile == RouteProfile.driving ? 'driving' : 'walking';
    final subtitleText = roadName != null && roadName.isNotEmpty
        ? 'Estimated $modeLabel time • via $roadName'
        : 'Estimated $modeLabel time';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(14, 8, 14, bottomInset + 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle pill at the top center
          Center(
            child: Container(
              width: 36,
              height: 3.5,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // ── 1. Unified Location Card: Origin on Left, Chevron, Destination on Right ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.75),
            ),
            child: Row(
              children: [
                // Origin side (POI)
                Expanded(
                  child: Row(
                    children: [
                      // Teal pin circle
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              resolvedOriginTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              resolvedOriginSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Middle separator chevron
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ),

                // Destination side (Property)
                Expanded(
                  child: Row(
                    children: [
                      // Soft slate circular container with house/dorm icon
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.home_work_outlined,
                            color: Color(0xFF334155),
                            size: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              resolvedDestTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              resolvedDestSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── 2. Metrics & Mode Switcher Row ─────────────────────────────────
          if (isLoadingRoute)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Calculating route...',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            )
          else if (plan != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Duration & Distance metrics
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            plan.formattedDuration,
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D), // Deep rich green
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${plan.formattedTotalDistance})',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Mode Selector Toggle [ Drive | Walk ]
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 0.75),
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModePill(RouteProfile.driving),
                      _buildModePill(RouteProfile.walking),
                    ],
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // ── 3. Route Preview Callout Banner (Clickable to Google Maps) ──────
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onLaunchGoogleMaps,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF), // Very soft sky-blue
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFBAE6FD), // Sky-200
                    width: 0.8,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Navigation circular icon
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.near_me_rounded,
                          color: Color(0xFF0284C7),
                          size: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Route Preview',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'This is a preview. For turn-by-turn guidance and voice navigation, continue in Google Maps.',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── 4. Action Controls: Open in Google Maps Primary Button & Close Button ──
          Row(
            children: [
              // Primary CTA: Open in Google Maps (Full teal with white Google Maps pin)
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onLaunchGoogleMaps,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppSvgIcon(
                          svgString: AppSvgIcons.googleMaps,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'Open in Google Maps',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Square Close Button
              SizedBox(
                height: 40,
                width: 40,
                child: Material(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onExit,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 0.9,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF475569),
                        ),
                      ),
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

  Widget _buildModePill(RouteProfile profile) {
    final isSelected = currentProfile == profile;
    return GestureDetector(
      onTap: () => onProfileChanged(profile),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE0F7FA).withValues(alpha: 0.7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              profile.icon,
              size: 14.5,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4.5),
            Text(
              profile.label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
