import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

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
    );
  }
}

class _BarChartPainter extends CustomPainter {
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
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
