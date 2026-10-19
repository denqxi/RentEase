import 'package:flutter/material.dart';

import '../model/navigation_models.dart';

/// Top Turn-by-Turn Navigation HUD (Google Maps style).
/// Displays the next maneuver arrow icon, distance to turn, and street name.
class LiveNavigationHud extends StatelessWidget {
  final NavigationStep? currentStep;
  final NavigationStep? nextStep;
  final VoidCallback onExit;

  const LiveNavigationHud({
    required this.currentStep,
    this.nextStep,
    required this.onExit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final step = currentStep;
    final icon = step?.maneuver.icon ?? Icons.straight_rounded;
    final distanceText = step?.formattedDistance ?? '--';
    final instruction = step?.displayInstruction ?? 'Proceed to route';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F5132), // Classic Google Maps navigation forest green
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Maneuver Arrow Icon in circular white container or bold white
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Distance & Instruction
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          distanceText,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          instruction,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Close/Exit Navigation Icon Button
                  IconButton(
                    onPressed: onExit,
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    tooltip: 'Exit navigation',
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                ],
              ),

              // Then Next Step Preview (if available)
              if (nextStep != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'THEN',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        nextStep!.maneuver.icon,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          nextStep!.roadName.isNotEmpty ? nextStep!.roadName : 'Continue',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
