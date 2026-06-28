import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// Teal-tinted card with a circular match gauge, title, summary and reason rows.
class MatchScoreCard extends StatelessWidget {
  const MatchScoreCard({
    required this.matchPercent,
    required this.label,
    required this.summary,
    required this.reasons,
    super.key,
  });

  final int matchPercent;
  final String label;
  final String summary;

  /// List of `(String label, bool met)` records.
  final List<(String, bool)> reasons;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _CircleGauge(percent: matchPercent),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: AppTextStyles.label(context).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(summary, style: AppTextStyles.caption(context).copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          ...reasons.map((r) => _ReasonRow(label: r.$1, met: r.$2)),
        ],
      ),
    );
  }
}

class _CircleGauge extends StatelessWidget {
  const _CircleGauge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _GaugePainter(percent: percent, trackColor: context.appColors.fieldBorder),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$percent%',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
              Text(
                'MATCH',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.percent, required this.trackColor});

  final int percent;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 6.0;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * percent / 100,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.percent != percent || old.trackColor != trackColor;
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: met ? AppColors.accent : context.appColors.textSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              met ? Icons.check : Icons.close,
              color: AppColors.onInk,
              size: 12,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption(context).copyWith(
                fontSize: 13,
                color: met ? context.appColors.textPrimary : context.appColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
