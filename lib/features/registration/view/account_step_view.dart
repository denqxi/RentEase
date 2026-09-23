import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/validators.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../cubit/registration_cubit.dart';
import '../widgets/form_step_layout.dart';
import '../widgets/gender_select_field.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/password_requirements.dart';
import '../widgets/terms_agreement_field.dart';

/// Step 1/3 — "Create your account".
class AccountStepView extends StatefulWidget {
  const AccountStepView({super.key});

  @override
  State<AccountStepView> createState() => _AccountStepViewState();
}

class _AccountStepViewState extends State<AccountStepView> {
  // Obscure toggle is purely local UI state for the password field.
  bool _obscurePassword = true;
  String _password = '';
  bool _agreedToTerms = false;

  /// Only shown once the user has attempted to continue, so fields don't
  /// flash red before they've had a chance to type anything.
  bool _showErrors = false;

  void _handleContinue(BuildContext context) {
    final data = context.read<RegistrationCubit>().state.data;
    final hasErrors = Validators.required(data.firstName, field: 'First name') != null ||
        Validators.required(data.lastName, field: 'Last name') != null ||
        Validators.required(data.gender, field: 'Gender') != null ||
        Validators.email(data.email) != null ||
        Validators.phone(data.phone) != null ||
        Validators.password(data.password) != null;

    if (hasErrors) {
      setState(() => _showErrors = true);
      return;
    }

    context.read<AuthBloc>().add(
          AuthSignUpRequested(
            email: data.email.trim(),
            password: data.password,
            firstName: data.firstName.trim(),
            lastName: data.lastName.trim(),
            gender: data.gender,
            phone: data.phone.trim(),
            role: 'tenant',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();
    final data = context.watch<RegistrationCubit>().state.data;
    final isLoading = context.select<AuthBloc, bool>(
      (bloc) => bloc.state is AuthLoading,
    );

    return FormStepLayout(
      title: 'Create your account',
      subtitle: 'Tell us a bit about you.',
      buttonLabel: isLoading ? 'Creating account…' : 'Continue',
      onContinue: (_agreedToTerms && !isLoading)
          ? () => _handleContinue(context)
          : null,
      footer: TermsAgreementField(
        value: _agreedToTerms,
        onChanged: (v) => setState(() => _agreedToTerms = v),
      ),
      fields: <Widget>[
        LabeledTextField(
          label: 'First name',
          hint: 'Jane',
          onChanged: cubit.updateFirstName,
          errorText: _showErrors
              ? Validators.required(data.firstName, field: 'First name')
              : null,
        ),
        LabeledTextField(
          label: 'Last name',
          hint: 'Doe',
          onChanged: cubit.updateLastName,
          errorText: _showErrors
              ? Validators.required(data.lastName, field: 'Last name')
              : null,
        ),
        GenderSelectField(
          value: data.gender,
          onChanged: cubit.updateGender,
          errorText: _showErrors
              ? Validators.required(data.gender, field: 'Gender')
              : null,
        ),
        LabeledTextField(
          label: 'Email',
          hint: 'jane@email.com',
          keyboardType: TextInputType.emailAddress,
          onChanged: cubit.updateEmail,
          errorText: _showErrors ? Validators.email(data.email) : null,
        ),
        LabeledTextField(
          label: 'Phone number',
          hint: '+63 912 345 6789',
          keyboardType: TextInputType.phone,
          onChanged: cubit.updatePhone,
          errorText: _showErrors ? Validators.phone(data.phone) : null,
        ),
        LabeledTextField(
          label: 'Password',
          hint: '12–16 characters',
          obscureText: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onChanged: (v) {
            cubit.updatePassword(v);
            setState(() => _password = v);
          },
          errorText: _showErrors ? Validators.password(data.password) : null,
        ),
        PasswordRequirements(password: _password),
      ],
    );
  }
}
