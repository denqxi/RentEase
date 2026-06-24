import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/registration_cubit.dart';
import '../widgets/age_range_field.dart';
import '../widgets/form_step_layout.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/preference_dropdown.dart';
import '../widgets/preference_toggle_row.dart';

/// Landlord step 4/4 — "Ideal tenant".
class IdealTenantStepView extends StatelessWidget {
  const IdealTenantStepView({super.key});

  static const List<String> _incomeRanges = <String>[
    'Any',
    'Under \$2,000',
    '\$2,000–\$3,500',
    '\$3,500–\$5,000',
    'Over \$5,000',
  ];

  static const List<String> _genderPreferences = <String>[
    'No preference',
    'Male',
    'Female',
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();
    final data = context.watch<RegistrationCubit>().state.data;

    return FormStepLayout(
      title: 'Ideal tenant',
      subtitle: 'Who are you hoping to match with?',
      buttonLabel: 'Save & finish',
      onContinue: cubit.next,
      fields: <Widget>[
        AgeRangeField(
          onMinChanged: cubit.updateMinAge,
          onMaxChanged: cubit.updateMaxAge,
        ),
        LabeledTextField(
          label: 'Preferred occupation',
          hint: 'Any',
          onChanged: cubit.updatePreferredOccupation,
        ),
        LabeledTextField(
          label: 'Maximum occupants',
          hint: 'e.g. 3',
          keyboardType: TextInputType.number,
          onChanged: cubit.updateMaxOccupants,
        ),
        PreferenceDropdown(
          label: 'Income range',
          value: data.incomeRange,
          items: _incomeRanges,
          onChanged: cubit.updateIncomeRange,
        ),
        PreferenceToggleRow(
          label: 'Pets allowed',
          leftLabel: 'Yes',
          rightLabel: 'No',
          leftSelected: data.petsAllowed,
          onChanged: cubit.setPetsAllowed,
        ),
        PreferenceToggleRow(
          label: 'Smoking allowed',
          leftLabel: 'Yes',
          rightLabel: 'No',
          leftSelected: data.smokingAllowed,
          onChanged: cubit.setSmokingAllowed,
        ),
        PreferenceToggleRow(
          label: 'Parking available',
          leftLabel: 'Yes',
          rightLabel: 'No',
          leftSelected: data.parkingAvailable,
          onChanged: cubit.setParkingAvailable,
        ),
        PreferenceToggleRow(
          label: 'Student-friendly',
          leftLabel: 'Yes',
          rightLabel: 'No',
          leftSelected: data.studentFriendly,
          onChanged: cubit.setStudentFriendly,
        ),
        PreferenceToggleRow(
          label: 'Family-friendly',
          leftLabel: 'Yes',
          rightLabel: 'No',
          leftSelected: data.familyFriendly,
          onChanged: cubit.setFamilyFriendly,
        ),
        PreferenceDropdown(
          label: 'Gender preference (optional)',
          value: data.genderPreference,
          items: _genderPreferences,
          onChanged: cubit.updateGenderPreference,
        ),
      ],
    );
  }
}
