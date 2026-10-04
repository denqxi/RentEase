import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';import '../cubit/analytics_cubit.dart';
import '../domain/entities/admin_entities.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_state_views.dart';
import 'admin_login_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({this.onGoToVerify, super.key});

  static const routeName = '/admin/analytics';

  /// Jumps to the Verify tab in [AdminShell] from the pending-review card.
  final VoidCallback? onGoToVerify;

  void _logout(BuildContext context) {
    final auth = context.read<AuthBloc>();
    final navigator = Navigator.of(context);
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
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Through AuthBloc so its state and suspension watcher reset.
              auth.add(const AuthSignOutRequested());
              navigator.pushReplacement(
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
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      builder: (context, state) {
        final stats = state.stats;
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
                child: stats == null
                    ? (state.isLoading
                          ? const AdminLoadingView()
                          : AdminMessageView(
                              icon: Icons.error_outline_rounded,
                              message:
                                  state.errorMessage ??
                                  'Could not load the dashboard.',
                              onRetry: context.read<AnalyticsCubit>().refresh,
                            ))
                    : RefreshIndicator(
                        color: AppColors.accent,
                        onRefresh: context.read<AnalyticsCubit>().refresh,
                        child: _Body(
                          stats: stats,
                          logs: state.logs,
                          onGoToVerify: onGoToVerify,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.stats, required this.logs, this.onGoToVerify});

  final AdminStats stats;
  final List<AdminLogDoc> logs;
  final VoidCallback? onGoToVerify;

  @override
  Widget build(BuildContext context) {
    final signups = stats.signupsLast7Days;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PendingReviewCard(
            count: stats.pendingVerifications,
            onReview: onGoToVerify,
          ),
          SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.5,
            children: [
              _MetricCard(
                label: 'Total users',
                value: '${stats.totalUsers}',
                delta: '${stats.tenants} tenants · ${stats.owners} owners',
                icon: Icons.people_alt_rounded,
                color: AppColors.accent,
              ),
              _MetricCard(
                label: 'Active listings',
                value: '${stats.activeProperties}',
                delta: 'of ${stats.properties} total',
                icon: Icons.home_work_rounded,
                color: AppColors.matchHigh,
              ),
              _MetricCard(
                label: 'Inquiries',
                value: '${stats.inquiries}',
                delta: 'all time',
                icon: Icons.mail_rounded,
                color: AppColors.matchMedium,
              ),
              _MetricCard(
                label: 'Bookings',
                value: '${stats.bookings}',
                delta: 'marked as booked',
                icon: Icons.event_available_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          const _SectionTitle('Sign-ups, last 7 days'),
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
            child: signups.isEmpty
                ? const SizedBox.shrink()
                : _BarChart(
                    values: [for (final d in signups) d.count],
                    labels: [for (final d in signups) _weekday(d.day)],
                  ),
          ),
          SizedBox(height: AppSpacing.lg),
          const _SectionTitle('User roles'),
          SizedBox(height: AppSpacing.sm),
          _RoleSplitCard(tenants: stats.tenants, owners: stats.owners),
          SizedBox(height: AppSpacing.lg),
          const _SectionTitle('Recent admin activity'),
          SizedBox(height: AppSpacing.xs),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No admin actions yet.',
                style: AppTextStyles.caption(context),
              ),
            )
          else
            ...logs.map((l) {
              final (label, icon, color) = _describe(l);
              return _ActivityRow(
                label: label,
                time: formatAdminDate(l.createdAt?.toDate()),
                icon: icon,
                color: color,
              );
            }),
        ],
      ),
    );
  }

  static String _weekday(DateTime d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];

  static (String, IconData, Color) _describe(AdminLogDoc l) =>
      switch (l.action) {
        'approve_owner' => (
          'Owner approved',
          Icons.verified_rounded,
          AppColors.matchHigh,
        ),
        'reject_owner' => (
          'Owner verification rejected',
          Icons.cancel_rounded,
          AppColors.destructive,
        ),
        'suspend_user' => (
          'Account suspended',
          Icons.block_rounded,
          AppColors.destructive,
        ),
        'reactivate_user' => (
          'Account reactivated',
          Icons.check_circle_rounded,
          AppColors.accent,
        ),
        'unlist_property' => (
          'Property unlisted',
          Icons.visibility_off_rounded,
          AppColors.matchMedium,
        ),
        'relist_property' => (
          'Property relisted',
          Icons.visibility_rounded,
          AppColors.primary,
        ),
        _ => (l.action, Icons.history_rounded, AppColors.accent),
      };
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
                  '$count owner${count == 1 ? "" : "s"} awaiting verification',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
                Text(
                  'Their listings are live, without the Verified badge, until approved.',
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
    final tenantFraction = total == 0 ? 0.5 : tenants / total;

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
              _LegendDot(color: AppColors.accent, label: 'Tenants · $tenants'),
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
    final maxVal = math.max(1, values.reduce(math.max)).toDouble();
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
          bottom: BorderSide(color: context.appColors.fieldBorder, width: 0.5),
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
              style: AppTextStyles.label(
                context,
              ).copyWith(fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ),
          Text(time, style: AppTextStyles.caption(context)),
        ],
      ),
    );
  }
}
