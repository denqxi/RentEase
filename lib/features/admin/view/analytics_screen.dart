import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  static const routeName = '/admin/analytics';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        title: Text(
          'Analytics',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.4,
              children: [
                _MetricCard(label: 'Total users', value: '1,284', color: AppColors.accent),
                _MetricCard(label: 'Active listings', value: '342', color: AppColors.matchHigh),
                _MetricCard(label: 'Matches this week', value: '89', color: AppColors.matchMedium),
                _MetricCard(label: 'Bookings this month', value: '56', color: AppColors.primary),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Weekly sign-ups',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
            ),
            SizedBox(height: AppSpacing.sm),
            Container(
              height: 180,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.appColors.fieldFill,
                borderRadius: BorderRadius.circular(AppRadii.field),
                border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
              ),
              child: const _BarChart(
                values: [24, 38, 30, 52, 44, 61, 47],
                labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Recent activity',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
            ),
            SizedBox(height: AppSpacing.sm),
            ...[
              ('Maria Santos registered as tenant', '2 hours ago', Icons.person_add_rounded, AppColors.accent),
              ('bh001 was matched with 3 tenants', '4 hours ago', Icons.handshake_rounded, AppColors.matchHigh),
              ('Carlos Mendoza verified as owner', '5 hours ago', Icons.verified_rounded, AppColors.primary),
              ('New inquiry submitted for bh002', '1 day ago', Icons.mail_rounded, AppColors.matchMedium),
              ('Benito Cruz account suspended', '2 days ago', Icons.block_rounded, AppColors.destructive),
            ].map((e) => _ActivityRow(label: e.$1, time: e.$2, icon: e.$3, color: e.$4)),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.caption(context)),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values, required this.labels});

  final List<int> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarChartPainter(
        values: values,
        labels: labels,
        labelColor: context.appColors.textSecondary,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.values,
    required this.labels,
    required this.labelColor,
  });

  final List<int> values;
  final List<String> labels;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = values.reduce(math.max).toDouble();
    final barWidth = (size.width - 40) / values.length;
    final textStyle = TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 10,
      color: labelColor,
    );

    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final barHeight = (values[i] / maxVal) * (size.height - 30);
      final left = 20 + i * barWidth + barWidth * 0.15;
      final top = size.height - 24 - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth * 0.7, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);

      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left + barWidth * 0.35 - tp.width / 2, size.height - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String label;
  final String time;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appColors.fieldBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTextStyles.label(context).copyWith(fontSize: 13, fontWeight: FontWeight.w400))),
          Text(time, style: AppTextStyles.caption(context)),
        ],
      ),
    );
  }
}
