<<<<<<< Updated upstream
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
=======
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
>>>>>>> Stashed changes

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

<<<<<<< Updated upstream
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
=======
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
>>>>>>> Stashed changes
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
<<<<<<< Updated upstream
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _MetricCard(
                  label: 'Total users',
                  value: '32',
                  valueColor: AppColors.primaryMid,
                ),
                _MetricCard(
                  label: 'Active listings',
                  value: '12',
                  valueColor: AppColors.primaryCyan,
                ),
                _MetricCard(
                  label: 'Match success rate',
                  value: '78%',
                  valueColor: AppColors.greenPrimary,
                ),
                _MetricCard(
                  label: 'Avg inquiries/listing',
                  value: '4.2',
                  valueColor: AppColors.amberPrimary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Monthly match activity',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 200,
              child: CustomPaint(
                painter: _BarChartPainter(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recent activity',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _ActivityTile(
              icon: Icons.person_add,
              title: 'New user registered',
              date: 'Jun 26, 2025',
            ),
            _ActivityTile(
              icon: Icons.verified,
              title: 'Listing verified',
              date: 'Jun 25, 2025',
            ),
            _ActivityTile(
              icon: Icons.check_circle,
              title: 'Booking confirmed',
              date: 'Jun 24, 2025',
            ),
            _ActivityTile(
              icon: Icons.handshake,
              title: 'Inquiry matched',
              date: 'Jun 23, 2025',
            ),
            _ActivityTile(
              icon: Icons.admin_panel_settings,
              title: 'Account approved',
              date: 'Jun 22, 2025',
            ),
=======
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
>>>>>>> Stashed changes
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
<<<<<<< Updated upstream
  const _MetricCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;
=======
  const _MetricCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    return Container(
<<<<<<< Updated upstream
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(10),
=======
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
>>>>>>> Stashed changes
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
<<<<<<< Updated upstream
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
=======
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
>>>>>>> Stashed changes
            ),
          ),
        ],
      ),
    );
  }
}

<<<<<<< Updated upstream
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.date,
  });

  final IconData icon;
  final String title;
  final String date;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.tenantFillBlue,
        child: Icon(icon, color: AppColors.primaryMid, size: 16),
      ),
      title: Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      trailing: Text(
        date,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
=======
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
>>>>>>> Stashed changes
    );
  }
}

class _BarChartPainter extends CustomPainter {
<<<<<<< Updated upstream
  final List<int> values = const [8, 12, 15, 10, 18, 22];
  final List<String> months = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

  @override
  void paint(Canvas canvas, Size size) {
    const int maxValue = 22;
    const double bottomPadding = 20;
    const double gapCount = 5;
    final double gapWidth = 8;
    final double totalGapWidth = gapCount * gapWidth;
    final double barWidth = (size.width - totalGapWidth) / 6;
    final double chartHeight = size.height - bottomPadding;

    final barPaint = Paint()..color = AppColors.primaryMid;
    final baselinePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    // Draw baseline
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      baselinePaint,
    );

    for (int i = 0; i < values.length; i++) {
      final double barHeight = (values[i] / maxValue) * chartHeight;
      final double left = i * (barWidth + gapWidth);
      final double top = chartHeight - barHeight;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, barHeight),
          const Radius.circular(4),
        ),
        barPaint,
      );

      // Month label
      final textPainter = TextPainter(
        text: TextSpan(
          text: months[i],
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          left + (barWidth - textPainter.width) / 2,
          chartHeight + 4,
        ),
      );
=======
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
>>>>>>> Stashed changes
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
<<<<<<< Updated upstream
=======

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
>>>>>>> Stashed changes
