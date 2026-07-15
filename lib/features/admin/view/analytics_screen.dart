import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/admin_page_header.dart';
import 'admin_login_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({this.onGoToVerify, super.key});

  static const routeName = '/admin/analytics';

  /// Jumps to the Verify tab in [AdminShell] from the pending-review card.
  final VoidCallback? onGoToVerify;

  void _logout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log out?',
          style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You will be returned to the admin sign-in screen.',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: ctx.appColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminLoginScreen(),
                ),
              );
            },
            child: Text(
              'Log out',
              style: TextStyle(
                color: AppColors.destructive,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: Column(
        children: [
          AdminPageHeader(
            title: 'Dashboard',
            subtitle: 'RentEase platform overview',
            trailing: AdminAvatarMenu(onLogout: () => _logout(context)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PendingReviewCard(count: 3, onReview: onGoToVerify),
                  SizedBox(height: AppSpacing.md),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.5,
                    children: const [
                      _MetricCard(
                        label: 'Total users',
                        value: '1,284',
                        delta: '+12% this month',
                        icon: Icons.people_alt_rounded,
                        color: AppColors.accent,
                      ),
                      _MetricCard(
                        label: 'Active listings',
                        value: '342',
                        delta: '+8 this week',
                        icon: Icons.home_work_rounded,
                        color: AppColors.matchHigh,
                      ),
                      _MetricCard(
                        label: 'Matches this week',
                        value: '89',
                        delta: 'B-score = 1 pairs',
                        icon: Icons.handshake_rounded,
                        color: AppColors.matchMedium,
                      ),
                      _MetricCard(
                        label: 'Bookings this month',
                        value: '56',
                        delta: '+21% vs May',
                        icon: Icons.event_available_rounded,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),
                  const _SectionTitle('Weekly sign-ups'),
                  SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: context.appColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.appColors.fieldBorder,
                        width: 0.5,
                      ),
                    ),
                    child: const _BarChart(
                      values: [24, 38, 30, 52, 44, 61, 47],
                      labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  const _SectionTitle('User roles'),
                  SizedBox(height: AppSpacing.sm),
                  const _RoleSplitCard(tenants: 1046, owners: 238),
                  SizedBox(height: AppSpacing.lg),
                  const _SectionTitle('Recent activity'),
                  SizedBox(height: AppSpacing.xs),
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
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: context.appColors.textPrimary,
      ),
    );
  }
}

/// Amber alert card surfacing owners waiting for verification — the admin's
/// most time-sensitive job — with a shortcut to the Verify tab.
class _PendingReviewCard extends StatelessWidget {
  const _PendingReviewCard({required this.count, this.onReview});

  final int count;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.matchMedium.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.matchMedium.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.matchMedium.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pending_actions_rounded,
              color: AppColors.matchMedium,
              size: 20,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count owners awaiting verification',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
                Text(
                  'They cannot list properties until approved.',
                  style: AppTextStyles.caption(context),
                ),
              ],
            ),
          ),
          if (onReview != null)
            GestureDetector(
              onTap: onReview,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.ink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Review',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onInk,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            delta,
            style: AppTextStyles.caption(context).copyWith(
              fontSize: 10.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Tenants-vs-owners proportion bar with a small legend.
class _RoleSplitCard extends StatelessWidget {
  const _RoleSplitCard({required this.tenants, required this.owners});

  final int tenants;
  final int owners;

  @override
  Widget build(BuildContext context) {
    final total = tenants + owners;
    final tenantFraction = tenants / total;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (tenantFraction * 100).round(),
                    child: Container(color: AppColors.accent),
                  ),
                  Expanded(
                    flex: ((1 - tenantFraction) * 100).round(),
                    child: Container(color: AppColors.matchMedium),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _LegendDot(
                color: AppColors.accent,
                label: 'Tenants · $tenants',
              ),
              SizedBox(width: AppSpacing.md),
              _LegendDot(
                color: AppColors.matchMedium,
                label: 'Owners · $owners',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption(context)),
      ],
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
      tp.paint(
        canvas,
        Offset(left + barWidth * 0.35 - tp.width / 2, size.height - 18),
      );
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
        border: Border(
          bottom: BorderSide(
            color: context.appColors.fieldBorder,
            width: 0.5,
          ),
        ),
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
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label(context)
                  .copyWith(fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ),
          Text(time, style: AppTextStyles.caption(context)),
        ],
      ),
    );
  }
}
