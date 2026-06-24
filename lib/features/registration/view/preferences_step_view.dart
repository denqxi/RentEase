import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/registration_cubit.dart';
import '../widgets/budget_range_field.dart';
import '../widgets/form_step_layout.dart';
import '../widgets/lifestyle_selector.dart';
import '../widgets/preference_dropdown.dart';
import '../widgets/preference_toggle_row.dart';
import '../widgets/property_type_selector.dart';

/// Step 3/3 — "Your preferences".
class PreferencesStepView extends StatelessWidget {
  const PreferencesStepView({super.key});

  static const List<String> _locations = <String>[
    'Downtown',
    'Suburbs',
    'Uptown',
    'Waterfront',
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
      title: 'Your preferences',
      subtitle: 'What are you looking for in a home?',
      buttonLabel: 'Save preferences',
      onContinue: cubit.next,
      fields: <Widget>[
        BudgetRangeField(value: data.budget, onChanged: cubit.updateBudget),
        PreferenceDropdown(
          label: 'Preferred location',
          value: data.preferredLocation,
          items: _locations,
          onChanged: cubit.updatePreferredLocation,
        ),
        PropertyTypeSelector(
          value: data.propertyType,
          onChanged: cubit.selectPropertyType,
        ),
        PreferenceToggleRow(
          label: 'Furnished',
          leftLabel: 'Yes',
          rightLabel: 'No',
          leftSelected: data.furnished,
          onChanged: cubit.setFurnished,
        ),
        PreferenceToggleRow(
          label: 'Pets allowed',
          leftLabel: 'Yes',
          rightLabel: 'No',
          leftSelected: data.petsAllowed,
          onChanged: cubit.setPetsAllowed,
        ),
        PreferenceToggleRow(
          label: 'Smoking',
          leftLabel: 'Non-smoker',
          rightLabel: 'Smoker',
          leftSelected: data.nonSmoker,
          onChanged: cubit.setNonSmoker,
        ),
        PreferenceToggleRow(
          label: 'Parking needed',
          leftLabel: 'Yes',
          rightLabel: 'No',
          leftSelected: data.parkingNeeded,
          onChanged: cubit.setParkingNeeded,
        ),
        PreferenceToggleRow(
          label: 'Wi-Fi required',
          leftLabel: 'Yes',
          rightLabel: 'No',
          leftSelected: data.wifiRequired,
          onChanged: cubit.setWifiRequired,
        ),
        PreferenceDropdown(
          label: 'Gender preference (optional)',
          value: data.genderPreference,
          items: _genderPreferences,
          onChanged: cubit.updateGenderPreference,
        ),
        LifestyleSelector(
          selected: data.lifestyles,
          onToggle: cubit.toggleLifestyle,
        ),
      ],
    );
  }
}
