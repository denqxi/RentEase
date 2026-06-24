import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/registration_cubit.dart';
import '../widgets/form_step_layout.dart';
import '../widgets/labeled_text_field.dart';

/// Landlord step 2/4 — "Your business".
class BusinessStepView extends StatelessWidget {
  const BusinessStepView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();

    return FormStepLayout(
      title: 'Your business',
      subtitle: 'A few details about your rental business.',
      buttonLabel: 'Continue',
      onContinue: cubit.next,
      fields: <Widget>[
        LabeledTextField(
          label: 'Property business name',
          hint: 'e.g. Smith Rentals',
          onChanged: cubit.updateBusinessName,
        ),
        LabeledTextField(
          label: 'Business address',
          hint: 'Street, City',
          onChanged: cubit.updateBusinessAddress,
        ),
        LabeledTextField(
          label: 'Years of experience',
          hint: 'e.g. 5',
          keyboardType: TextInputType.number,
          onChanged: cubit.updateYearsOfExperience,
        ),
      ],
    );
  }
}
