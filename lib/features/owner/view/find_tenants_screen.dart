import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/qualified_badge.dart';
import '../../auth/presentation/current_uid.dart';
import '../cubit/find_tenants_cubit.dart';
import '../data/repositories/find_tenants_repository_impl.dart';
import '../model/compatible_tenant.dart';

/// Owner-side discovery: compatible (bScore = 1) tenants for one of the
/// owner's properties. Filtering-only — there is no owner-side TOPSIS
/// instance (CLAUDE.md), so this list isn't ranked.
class FindTenantsScreen extends StatelessWidget {
  const FindTenantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ownerId = currentUidOrNull(context);
    if (ownerId == null) {
      // Signed out, or rendered by the offline screenshot harness.
      return const _FindTenantsScaffold(
        body: _Message(text: 'Sign in as an owner to find tenants.'),
      );
    }
    return BlocProvider(
      create: (_) => FindTenantsCubit(
        ownerId: ownerId,
        repository: FindTenantsRepositoryImpl(),
      ),
      child: const _FindTenantsView(),
    );
  }
}

class _FindTenantsScaffold extends StatelessWidget {
  const _FindTenantsScaffold({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        title: Text(
          'Find tenants',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      body: body,
    );
  }
}

class _FindTenantsView extends StatelessWidget {
  const _FindTenantsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FindTenantsCubit, FindTenantsState>(
      builder: (context, state) {
        final cubit = context.read<FindTenantsCubit>();
        final listing = state.selectedListing;

        if (state.isLoading && state.listings.isEmpty) {
          return const _FindTenantsScaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.errorMessage != null && state.listings.isEmpty) {
          return _FindTenantsScaffold(
            body: _Message(text: state.errorMessage!, onRetry: cubit.load),
          );
        }
        if (state.listings.isEmpty) {
          return const _FindTenantsScaffold(
            body: _Message(
              text: 'Add a property first — compatible tenants are matched '
                  'against its rules.',
            ),
          );
        }

        return _FindTenantsScaffold(
          body: RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              children: [
                if (state.listings.length > 1) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final l in state.listings)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.sm,
                            ),
                            child: ChoiceChip(
                              label: Text(l.title),
                              selected: l.propertyId == state.selectedPropertyId,
                              selectedColor: AppColors.accentSoft,
                              onSelected: (_) =>
                                  cubit.selectProperty(l.propertyId),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                ],
                if (listing != null)
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final rule in listing.ruleLabels)
                        AppChip(
                          label: rule,
                          variant: AppChipVariant.owner,
                          isLocked: true,
                        ),
                    ],
                  ),
                SizedBox(height: AppSpacing.sm),
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.errorMessage != null)
                  _Message(text: state.errorMessage!, onRetry: cubit.load)
                else if (state.tenants.isEmpty)
                  const _Message(
                    text: 'No compatible tenants yet. Tenants appear here once '
                        'their matching runs and they pass all of your '
                        'rules — check back later.',
                  )
                else ...[
                  Text(
                    '${state.tenants.length} qualified '
                    '${state.tenants.length == 1 ? 'tenant' : 'tenants'}',
                    style: AppTextStyles.caption(context),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  for (final t in state.tenants) ...[
                    _TenantCard(tenant: t),
                    SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: AppTextStyles.body(context),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Try again',
              variant: AppButtonVariant.outline,
              isSmall: true,
              isFullWidth: false,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({required this.tenant});

  final CompatibleTenant tenant;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (tenant.gender.isNotEmpty) tenant.gender,
      if (tenant.occupation?.isNotEmpty ?? false) tenant.occupation!,
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.accentSoft,
            child: Text(
              tenant.initials,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.appColors.ink,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenant.name,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                if (details.isNotEmpty)
                  Text(details, style: AppTextStyles.caption(context)),
                if (tenant.school?.isNotEmpty ?? false)
                  Text(tenant.school!, style: AppTextStyles.caption(context)),
                Text(
                  '₱${tenant.maxBudget}/mo budget',
                  style: AppTextStyles.caption(context),
                ),
                SizedBox(height: AppSpacing.sm),
                const QualifiedBadge(),
                SizedBox(height: AppSpacing.sm),
                // CLAUDE.md rule 2: absent, never disabled, when bScore = 0.
                if (tenant.bScore == 1)
                  AppButton(
                    label: 'Invite',
                    variant: AppButtonVariant.outline,
                    isSmall: true,
                    isFullWidth: false,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invitation sent to ${tenant.name}!'),
                        backgroundColor: context.appColors.ink,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
