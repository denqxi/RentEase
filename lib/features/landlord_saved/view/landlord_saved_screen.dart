import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../landlord_home/cubit/landlord_home_cubit.dart';
import '../../landlord_home/model/tenant.dart';
import '../../landlord_home/model/tenant_detail.dart';
import '../../landlord_home/view/tenant_detail_screen.dart';
import '../../landlord_home/widgets/tenant_card.dart';
import '../../shell/cubit/shell_cubit.dart';

/// Saved tab — tenants the landlord bookmarked, with empty state.
class LandlordSavedScreen extends StatelessWidget {
  const LandlordSavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tenants = context
        .select<LandlordHomeCubit, List<Tenant>>((c) => c.state.saved);
    final cubit = context.read<LandlordHomeCubit>();

    return Scaffold(
      backgroundColor: tenants.isEmpty ? AppColors.surface : AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Saved', style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Applicants you saved for later',
                      style: AppTextStyles.caption.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            if (tenants.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  onBrowse: () =>
                      context.read<ShellCubit>().selectTab(ShellTab.home),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                sliver: SliverList.separated(
                  itemCount: tenants.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, i) => TenantCard(
                    tenant: tenants[i],
                    onSaveToggle: () => cubit.toggleSaved(tenants[i].id),
                    onTap: () => Navigator.of(ctx).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            TenantDetailScreen(detail: TenantDetail.sample),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: const Icon(Icons.favorite_border, color: AppColors.textSecondary, size: 32),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Nothing saved yet',
          style: AppTextStyles.label.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tap the heart on any tenant to keep\nthem here.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: 200,
          height: AppSizes.buttonHeight,
          child: ElevatedButton(
            onPressed: onBrowse,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.onInk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
            ),
            child: const Text('Browse now', style: AppTextStyles.buttonLabel),
          ),
        ),
      ],
    );
  }
}
