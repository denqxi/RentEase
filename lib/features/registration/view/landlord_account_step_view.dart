import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/registration_cubit.dart';
import '../widgets/form_step_layout.dart';
import '../widgets/labeled_text_field.dart';

/// Landlord step 1/4 — "Create your account".
class LandlordAccountStepView extends StatefulWidget {
  const LandlordAccountStepView({super.key});

  @override
  State<LandlordAccountStepView> createState() =>
      _LandlordAccountStepViewState();
}

class _LandlordAccountStepViewState extends State<LandlordAccountStepView> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();

    return FormStepLayout(
      title: 'Create your account',
      subtitle: 'Set up your landlord profile.',
      buttonLabel: 'Continue',
      onContinue: cubit.next,
      fields: <Widget>[
        LabeledTextField(
          label: 'Full name',
          hint: 'John Smith',
          onChanged: cubit.updateFullName,
        ),
        LabeledTextField(
          label: 'Email',
          hint: 'john@email.com',
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
