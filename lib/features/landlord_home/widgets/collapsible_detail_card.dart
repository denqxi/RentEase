import 'package:flutter/material.dart';

/// An expandable section card with an icon, title, optional badge,
/// rotating chevron, and smooth expansion animation.
class CollapsibleDetailCard extends StatefulWidget {
  const CollapsibleDetailCard({
    required this.icon,
    this.iconColor,
    required this.title,
    this.badgeWidget,
    required this.child,
    this.initiallyExpanded = true,
    super.key,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final Widget? badgeWidget;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<CollapsibleDetailCard> createState() => _CollapsibleDetailCardState();
}

class _CollapsibleDetailCardState extends State<CollapsibleDetailCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = widget.iconColor ?? const Color(0xFF00A8F0);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 18, color: effectiveIconColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (widget.badgeWidget != null) ...[
                      widget.badgeWidget!,
                      const SizedBox(width: 8),
                    ],
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                widget.child,
              ],
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
