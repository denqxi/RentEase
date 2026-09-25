import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/user_role.dart';

/// Selectable card representing a [UserRole] on the "Join RentEase" screen.
///
/// Features an 8-second color spread animation expanding outwards from the
/// tap epicenter across the card, a gentle glow, and a smooth scale-up
/// animation for the selection circle.
class RoleOptionCard extends StatefulWidget {
  const RoleOptionCard({
    required this.role,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<RoleOptionCard> createState() => _RoleOptionCardState();
}

class _RoleOptionCardState extends State<RoleOptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _spreadAnimation;
  late final Animation<double> _radioScaleAnimation;
  late final Animation<double> _glowAnimation;

  Offset? _tapEpicenter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    // 8-second smooth color spread curve
    _spreadAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // Scale up animation for the selection circle
    _radioScaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
    );

    // Subtle glow bloom and gentle fade out
    _glowAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutQuad),
    );

    if (widget.selected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(RoleOptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selected && widget.selected) {
      _controller.forward(from: 0.0);
    } else if (oldWidget.selected && !widget.selected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getSelectedBackgroundColor(UserRole role) {
    switch (role) {
      case UserRole.tenant:
        return const Color(0xFFE3F4F7);
      case UserRole.landlord:
        return const Color(0xFFE8EEF5);
      case UserRole.guest:
        return const Color(0xFFFFF5E6);
    }
  }

  Color _getSelectedBorderColor(UserRole role) {
    switch (role) {
      case UserRole.tenant:
        return const Color(0xFFBCE5EC);
      case UserRole.landlord:
        return const Color(0xFFC7D9EC);
      case UserRole.guest:
        return const Color(0xFFF7E2C4);
    }
  }

  Color _getGlowColor(UserRole role) {
    switch (role) {
      case UserRole.tenant:
        return const Color(0xFF1ABCCE);
      case UserRole.landlord:
        return const Color(0xFF2C5282);
      case UserRole.guest:
        return const Color(0xFFDD6B20);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedBg = _getSelectedBackgroundColor(widget.role);
    final selectedBorder = _getSelectedBorderColor(widget.role);
    final glowColor = _getGlowColor(widget.role);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _spreadAnimation.value;
          final glowProgress = _glowAnimation.value;
          final glowAlpha = (1.0 - glowProgress) * (widget.selected ? 0.25 : 0.0);
          final glowBlur = 8.0 + (glowProgress * 12.0);

          final currentBorderColor = Color.lerp(
            AppColors.fieldBorder.withValues(alpha: 0.35),
            selectedBorder,
            progress,
          )!;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: currentBorderColor,
                width: 1.0 + (0.5 * progress),
              ),
              boxShadow: [
                // 1. Temporary subtle glow bloom on selection
                if (glowAlpha > 0.01)
                  BoxShadow(
                    color: glowColor.withValues(alpha: glowAlpha),
                    blurRadius: glowBlur,
                    spreadRadius: (1.0 - glowProgress) * 2.0,
                    offset: const Offset(0, 2),
                  ),
                // 2. Minimal persistent ambient shadow for the selected option
                if (progress > 0.01)
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.10 * progress),
                    blurRadius: 10 * progress,
                    offset: Offset(0, 3 * progress),
                  ),
                // 3. Crisp base drop shadow
                BoxShadow(
                  color: Color.lerp(
                    const Color(0x0A000000),
                    const Color(0x14000000),
                    progress,
                  )!,
                  blurRadius: 8 + (4 * progress),
                  offset: Offset(0, 2 + (2 * progress)),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.card - 1),
              child: CustomPaint(
                painter: _EpicenterSpreadPainter(
                  progress: progress,
                  epicenter: _tapEpicenter,
                  baseColor: AppColors.surface,
                  spreadColor: selectedBg,
                ),
                child: child,
              ),
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.card),
            splashColor: selectedBg.withValues(alpha: 0.4),
            highlightColor: selectedBg.withValues(alpha: 0.2),
            onTapDown: (details) {
              _tapEpicenter = details.localPosition;
            },
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: <Widget>[
                  ClipOval(
                    child: Image.asset(
                      widget.role.imagePath,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.role.label,
                          style: AppTextStyles.label(context)
                              .copyWith(fontSize: 17),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.role.description,
                          style: AppTextStyles.body(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _RadioDot(
                    selected: widget.selected,
                    role: widget.role,
                    scaleAnimation: _radioScaleAnimation,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter that smoothly renders an expanding circular color wave
/// from the tap epicenter across the entire card.
class _EpicenterSpreadPainter extends CustomPainter {
  const _EpicenterSpreadPainter({
    required this.progress,
    required this.epicenter,
    required this.baseColor,
    required this.spreadColor,
  });

  final double progress;
  final Offset? epicenter;
  final Color baseColor;
  final Color spreadColor;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw base card surface
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, basePaint);

    // 2. Draw circular color spread from epicenter
    if (progress > 0.0) {
      final center = epicenter ?? Offset(size.width / 2, size.height / 2);
      final d1 = (center - Offset.zero).distance;
      final d2 = (center - Offset(size.width, 0)).distance;
      final d3 = (center - Offset(0, size.height)).distance;
      final d4 = (center - Offset(size.width, size.height)).distance;
      final maxRadius = math.max(math.max(d1, d2), math.max(d3, d4));

      final spreadPaint = Paint()
        ..color = spreadColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, maxRadius * progress, spreadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EpicenterSpreadPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.epicenter != epicenter ||
        oldDelegate.spreadColor != spreadColor ||
        oldDelegate.baseColor != baseColor;
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({
    required this.selected,
    required this.role,
    required this.scaleAnimation,
  });

  final bool selected;
  final UserRole role;
  final Animation<double> scaleAnimation;

  Color _getRadioColor(UserRole role) {
    switch (role) {
      case UserRole.tenant:
        return const Color(0xFF0E8FA0);
      case UserRole.landlord:
        return const Color(0xFF2C5282);
      case UserRole.guest:
        return const Color(0xFFDD6B20);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getRadioColor(role);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? activeColor : AppColors.fieldBorder,
          width: 2,
        ),
      ),
      child: selected
          ? ScaleTransition(
              scale: scaleAnimation,
              child: Center(
                child: CircleAvatar(radius: 5, backgroundColor: activeColor),
              ),
            )
          : null,
    );
  }
}
