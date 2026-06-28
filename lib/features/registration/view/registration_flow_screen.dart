import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../cubit/registration_cubit.dart';
import '../model/registration_step.dart';
import '../model/user_role.dart';
import '../widgets/registration_app_bar.dart';
import 'about_step_view.dart';
import 'account_step_view.dart';
import 'business_step_view.dart';
import 'ideal_tenant_step_view.dart';
import 'landlord_account_step_view.dart';
import 'preferences_step_view.dart';
import 'property_step_view.dart';
import 'role_selection_view.dart';
import 'success_view.dart';

/// Host for the multi-step registration flow.
///
/// Provides the [RegistrationCubit] and renders the view matching the current
/// [RegistrationStep]. [onComplete] runs on "Explore RentEase"; [onSignIn]
/// runs from the role screen's "Sign in" / back affordances.
class RegistrationFlowScreen extends StatelessWidget {
  const RegistrationFlowScreen({
    required this.onComplete,
    required this.onSignIn,
    super.key,
  });

  final ValueChanged<UserRole> onComplete;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistrationCubit>(
      create: (_) => RegistrationCubit(),
      child: BlocListener<RegistrationCubit, RegistrationState>(
        listenWhen: (prev, curr) =>
            curr.step == RegistrationStep.success &&
            prev.step != RegistrationStep.success,
        listener: (context, state) {
          onComplete(state.data.role ?? UserRole.tenant);
        },
        child: Scaffold(
          backgroundColor: context.appColors.surface,
          body: SafeArea(
            child: BlocBuilder<RegistrationCubit, RegistrationState>(
              buildWhen: (previous, current) => previous.step != current.step,
              builder: (context, state) {
                final cubit = context.read<RegistrationCubit>();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        0,
                      ),
                      child: RegistrationAppBar(
                        onBack: state.step == RegistrationStep.role
                            ? onSignIn
                            : cubit.back,
                        stepNumber: state.step.formStepNumber,
                        stepCount: state.formStepCount,
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: KeyedSubtree(
                          key: ValueKey<RegistrationStep>(state.step),
                          child: _viewForStep(state.step, context),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewForStep(RegistrationStep step, BuildContext context) {
    return switch (step) {
      RegistrationStep.role => RoleSelectionView(onSignIn: onSignIn),
      RegistrationStep.account => const AccountStepView(),
      RegistrationStep.about => const AboutStepView(),
      RegistrationStep.preferences => const PreferencesStepView(),
      RegistrationStep.landlordAccount => const LandlordAccountStepView(),
      RegistrationStep.business => const BusinessStepView(),
      RegistrationStep.property => const PropertyStepView(),
      RegistrationStep.idealTenant => const IdealTenantStepView(),
      RegistrationStep.success => SuccessView(
          onExplore: () => onComplete(
            context.read<RegistrationCubit>().state.data.role ??
                UserRole.tenant,
          ),
        ),
    };
  }
}
