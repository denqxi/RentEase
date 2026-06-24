import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/registration_cubit.dart';
import '../widgets/form_step_layout.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/photo_picker_field.dart';
import '../widgets/property_type_selector.dart';

/// Landlord step 3/4 — "Your property".
class PropertyStepView extends StatelessWidget {
  const PropertyStepView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();
    final data = context.watch<RegistrationCubit>().state.data;

    return FormStepLayout(
      title: 'Your property',
      subtitle: 'Add the listing tenants will be matched to.',
      buttonLabel: 'Continue',
      onContinue: cubit.next,
      fields: <Widget>[
        LabeledTextField(
          label: 'Property name',
          hint: 'e.g. Maple Court, Apt 4B',
          onChanged: cubit.updatePropertyName,
        ),
        LabeledTextField(
          label: 'Address',
          hint: 'Street, City',
          onChanged: cubit.updatePropertyAddress,
        ),
        LabeledTextField(
          label: 'Monthly rent',
          hint: 'e.g. 1,800',
          prefixText: '\$  ',
          keyboardType: TextInputType.number,
          onChanged: cubit.updateMonthlyRent,
        ),
        LabeledTextField(
          label: 'Number of rooms',
          hint: 'e.g. 3',
          keyboardType: TextInputType.number,
          onChanged: cubit.updateNumberOfRooms,
        ),
        PropertyTypeSelector(
          value: data.propertyType,
          onChanged: cubit.selectPropertyType,
        ),
        LabeledTextField(
          label: 'Description',
          hint: 'Describe the property, neighbourhood, and what makes it '
              'special...',
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          onChanged: cubit.updatePropertyDescription,
        ),
        const PhotoPickerField(),
      ],
    );
  }
}
