import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/match_score_card.dart';
import '../cubit/tenant_detail_cubit.dart';
import '../model/tenant_detail.dart';

/// Full-screen detail view for a tenant applicant (landlord perspective).
class TenantDetailScreen extends StatelessWidget {
  const TenantDetailScreen({required this.detail, super.key});

  final TenantDetail detail;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TenantDetailCubit>(
      create: (_) => TenantDetailCubit(detail: detail),
      child: const _TenantDetailView(),
    );
  }
}

class _TenantDetailView extends StatelessWidget {
  const _TenantDetailView();

  @override
  Widget build(BuildContext context) {
    final detail = context
        .select<TenantDetailCubit, TenantDetail>((c) => c.state.detail);
    final cubit = context.read<TenantDetailCubit>();

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: Stack(
        children: <Widget>[
          CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _CircleButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  100,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    _AvatarSection(detail: detail),
                    SizedBox(height: AppSpacing.md),
                    MatchScoreCard(
                      matchPercent: detail.matchPercent,
                      label: detail.matchLabel,
                      summary: detail.matchSummary,
                      reasons: detail.matchReasons
                          .map((r) => (r.label, r.met))
                          .toList(),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Text(
                      'Applicant details',
                      style: AppTextStyles.title(context).copyWith(fontSize: 18),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _ApplicantDetailsTable(detail: detail),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomBar(
              isSaved: detail.isSaved,
              onSaveToggle: cubit.toggleSaved,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.appColors.fieldFill,
          shape: BoxShape.circle,
          border: Border.all(color: context.appColors.fieldBorder),
        ),
        child: Icon(Icons.arrow_back, size: 18, color: context.appColors.textPrimary),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.detail});

  final TenantDetail detail;

  static const List<List<Color>> _palettes = <List<Color>>[
    <Color>[Color(0xFFDBC59C), Color(0xFF8B6914)],
    <Color>[Color(0xFF2C3E6B), Color(0xFF0D1B3A)],
    <Color>[Color(0xFFB0D4E0), Color(0xFF5A9AB0)],
    <Color>[Color(0xFFCDAA8C), Color(0xFF8B6250)],
    <Color>[Color(0xFF4AA8D8), Color(0xFF1E5C8A)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _palettes[(detail.imageSeed - 1) % _palettes.length];
    return Column(
      children: <Widget>[
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(Icons.person, color: AppColors.onInk, size: 40),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          detail.name,
          style: AppTextStyles.title(context).copyWith(fontSize: 20),
        ),
        SizedBox(height: 2),
        Text(
          '${detail.occupation} · ${detail.incomeRange}',
          style: AppTextStyles.caption(context).copyWith(fontSize: 13),
        ),
      ],
    );
  }
}

class _ApplicantDetailsTable extends StatelessWidget {
  const _ApplicantDetailsTable({required this.detail});

  final TenantDetail detail;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Occupation', detail.occupation),
      ('Monthly income', detail.monthlyIncome),
      ('Occupants', detail.occupants),
      ('Smoking', detail.smoking),
      ('Pets', detail.pets),
      ('Move-in', detail.moveIn),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        children: List<Widget>.generate(rows.length, (i) {
          final isLast = i == rows.length - 1;
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        rows[i].$1,
                        style: AppTextStyles.caption(context).copyWith(fontSize: 13),
                      ),
                    ),
                    Text(
                      rows[i].$2,
                      style: AppTextStyles.label(context).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: context.appColors.fieldBorder),
            ],
          );
        }),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.isSaved, required this.onSaveToggle});

  final bool isSaved;
  final VoidCallback onSaveToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border(top: BorderSide(color: context.appColors.fieldBorder)),
      ),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onSaveToggle,
            child: Container(
              width: AppSizes.buttonHeight,
              height: AppSizes.buttonHeight,
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.button),
                border: Border.all(color: context.appColors.fieldBorder),
              ),
              child: Icon(
                isSaved ? Icons.favorite_rounded : Icons.favorite_border,
                color: isSaved ? AppColors.destructive : context.appColors.textSecondary,
                size: 22,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: SizedBox(
              height: AppSizes.buttonHeight,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appColors.ink,
                  foregroundColor: AppColors.onInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.button),
                  ),
                ),
                child: Text('Contact tenant', style: AppTextStyles.buttonLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
