import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
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
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${state.tenants.length}',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRouter.findTenants),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
          width: 0.75,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 22,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}
