import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/registration_cubit.dart';
import '../widgets/form_step_layout.dart';
import '../widgets/labeled_text_field.dart';

/// Step 1/3 — "Create your account".
class AccountStepView extends StatefulWidget {
  const AccountStepView({super.key});

  @override
  State<AccountStepView> createState() => _AccountStepViewState();
}

class _AccountStepViewState extends State<AccountStepView> {
  // Obscure toggle is purely local UI state for the password field.
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();

    return FormStepLayout(
      title: 'Create your account',
      subtitle: 'Tell us a bit about you.',
      buttonLabel: 'Continue',
      onContinue: cubit.next,
      fields: <Widget>[
        LabeledTextField(
          label: 'First name',
          hint: 'Jane',
          onChanged: cubit.updateFirstName,
        ),
        LabeledTextField(
          label: 'Last name',
          hint: 'Doe',
          onChanged: cubit.updateLastName,
        ),
        LabeledTextField(
          label: 'Email',
          hint: 'jane@email.com',
          keyboardType: TextInputType.emailAddress,
          onChanged: cubit.updateEmail,
        ),
        LabeledTextField(
          label: 'Phone number',
          hint: '+1 555 000 1234',
          keyboardType: TextInputType.phone,
          onChanged: cubit.updatePhone,
        ),
        LabeledTextField(
          label: 'Password',
          hint: 'At least 8 characters',
          obscureText: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onChanged: cubit.updatePassword,
        ),
      ],
    );
  }
}
