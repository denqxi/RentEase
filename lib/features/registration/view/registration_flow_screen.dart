import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/registration_cubit.dart';
import '../model/registration_step.dart';
import '../model/user_role.dart';
import '../widgets/registration_app_bar.dart';
import 'about_step_view.dart';
import 'account_step_view.dart';
import 'check_email_view.dart';
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
      child: BlocListener<AuthBloc, AuthState>(
        // The account/landlordAccount step dispatches AuthSignUpRequested
        // directly (see AccountStepView/LandlordAccountStepView) — once it
        // resolves we either advance to the success step or surface the
        // error and let the user retry from the same step.
        listener: (context, state) {
          final cubit = context.read<RegistrationCubit>();
          final currentStep = cubit.state.step;
          final onAccountStep = currentStep == RegistrationStep.account ||
              currentStep == RegistrationStep.landlordAccount;
          if (!onAccountStep) return;

          if (state is AuthEmailNotVerified) {
            // Account created — hand off to email verification, which then
            // leads into the role's onboarding (tenant hard constraints /
            // owner document upload). The "You're all set" success step is
            // not shown here: it belongs after onboarding, not before it.
            onComplete(cubit.state.data.role ?? UserRole.tenant);
          } else if (state is AuthOperationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.destructive,
              ),
            );
          }
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
      RegistrationStep.checkEmail => const CheckEmailView(),
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
