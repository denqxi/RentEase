import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/landlord_home_cubit.dart';
import '../view/tenant_detail_screen.dart';
import 'tenant_card.dart';

/// "Compatible tenants" list (unranked) with the loading / empty /
/// error states. Used by the owner home and the Matches tab.
class CompatibleTenantsSection extends StatelessWidget {
  const CompatibleTenantsSection({this.limit, super.key});

  /// Max cards to show (home preview); null shows all.
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LandlordHomeCubit>().state;
    final cubit = context.read<LandlordHomeCubit>();
    final tenants = limit == null
        ? state.tenants
        : state.tenants.take(limit!).toList();

    Widget body;
    if (state.isLoading || (state.tenantsLoading && state.tenants.isEmpty)) {
      body = const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (state.tenantsError != null) {
      body = _Note(
        icon: Icons.error_outline_rounded,
        text: state.tenantsError!,
        onRetry: cubit.reloadTenants,
      );
    } else if (tenants.isEmpty) {
      body = const _Note(
        icon: Icons.people_outline_rounded,
        text: 'No compatible tenants yet. They appear here once their '
            'matching runs and they pass all of your rules.',
      );
    } else {
      body = Column(
        children: [
          for (final t in tenants) ...[
            TenantCard(
              tenant: t,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TenantDetailScreen(tenant: t),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (limit != null)
          Row(
            children: [
              Text(
                'Compatible tenants',
                style: AppTextStyles.title(context).copyWith(fontSize: 18),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                      Navigator.of(context).pushNamed(AppRouter.findTenants),
                  child: Text(
                    'See all',
                    style: AppTextStyles.link(context)
                        .copyWith(color: AppColors.primary),
                  ),
                ),
            ],
          ),
        if (limit != null) const SizedBox(height: AppSpacing.sm),
        body,
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: context.appColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(context),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
