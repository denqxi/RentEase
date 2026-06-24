import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/registration_cubit.dart';
import '../widgets/form_step_layout.dart';
import '../widgets/labeled_text_field.dart';

/// Step 2/3 — "About you".
class AboutStepView extends StatelessWidget {
  const AboutStepView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();

    return FormStepLayout(
      title: 'About you',
      subtitle: 'This helps us find your best matches.',
      buttonLabel: 'Continue',
      onContinue: cubit.next,
      fields: <Widget>[
        LabeledTextField(
          label: 'Age',
          hint: 'e.g. 24',
          keyboardType: TextInputType.number,
          onChanged: cubit.updateAge,
        ),
        LabeledTextField(
          label: 'Occupation',
          hint: 'e.g. Software Engineer',
          onChanged: cubit.updateOccupation,
        ),
        LabeledTextField(
          label: 'Monthly income',
          hint: 'e.g. 3,500',
          prefixText: '\$  ',
          keyboardType: TextInputType.number,
          onChanged: cubit.updateMonthlyIncome,
        ),
        LabeledTextField(
          label: 'Number of occupants',
          hint: 'e.g. 2',
          keyboardType: TextInputType.number,
          onChanged: cubit.updateOccupants,
        ),
        LabeledTextField(
          label: 'Current address',
          hint: 'Street, City',
          onChanged: cubit.updateCurrentAddress,
        ),
      ],
    );
  }
}
