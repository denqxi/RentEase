import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/lifestyle_preference.dart';
import '../model/property_type.dart';
import '../model/registration_data.dart';
import '../model/registration_step.dart';
import '../model/user_role.dart';

part 'registration_state.dart';

/// Drives the multi-step registration flow: tracks the current step and the
/// data collected at each one.
///
/// Widgets push field updates here (no business logic lives in the UI) and the
/// view renders the screen matching [RegistrationState.step].
class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit() : super(const RegistrationState());

  static const List<RegistrationStep> _tenantOrder = <RegistrationStep>[
    RegistrationStep.role,
    RegistrationStep.account,
    RegistrationStep.checkEmail,
    RegistrationStep.about,
    RegistrationStep.preferences,
    RegistrationStep.success,
  ];

  static const List<RegistrationStep> _landlordOrder = <RegistrationStep>[
    RegistrationStep.role,
    RegistrationStep.landlordAccount,
    RegistrationStep.checkEmail,
    RegistrationStep.business,
    RegistrationStep.property,
    RegistrationStep.idealTenant,
    RegistrationStep.success,
  ];

  List<RegistrationStep> get _order =>
      state.data.role == UserRole.landlord ? _landlordOrder : _tenantOrder;

  // ── Navigation ───────────────────────────────────────────────────────────

  /// Advances to the next step in the flow.
  void next() {
    final index = _order.indexOf(state.step);
    if (index < _order.length - 1) {
      emit(state.copyWith(step: _order[index + 1]));
    }
  }

  /// Returns to the previous step. Does nothing on the first step.
  void back() {
    final index = _order.indexOf(state.step);
    if (index > 0) {
      emit(state.copyWith(step: _order[index - 1]));
    }
  }

  /// Resets the whole flow back to the start (e.g. "Back to start").
  void restart() => emit(const RegistrationState());

  // ── Role ─────────────────────────────────────────────────────────────────

  void selectRole(UserRole role) {
    emit(state.copyWith(data: state.data.copyWith(role: role)));
  }

  // ── Account step ───────────────────────────────────────────────────────────

  void updateFirstName(String value) =>
      emit(state.copyWith(data: state.data.copyWith(firstName: value)));

  void updateLastName(String value) =>
      emit(state.copyWith(data: state.data.copyWith(lastName: value)));

  void updateEmail(String value) =>
      emit(state.copyWith(data: state.data.copyWith(email: value)));

  void updatePhone(String value) =>
      emit(state.copyWith(data: state.data.copyWith(phone: value)));

  void updatePassword(String value) =>
      emit(state.copyWith(data: state.data.copyWith(password: value)));

  // ── About-you step ─────────────────────────────────────────────────────────

  void updateAge(String value) =>
      emit(state.copyWith(data: state.data.copyWith(age: value)));

  void updateOccupation(String value) =>
      emit(state.copyWith(data: state.data.copyWith(occupation: value)));

  void updateMonthlyIncome(String value) =>
      emit(state.copyWith(data: state.data.copyWith(monthlyIncome: value)));

  void updateOccupants(String value) =>
      emit(state.copyWith(data: state.data.copyWith(occupants: value)));

  void updateCurrentAddress(String value) =>
      emit(state.copyWith(data: state.data.copyWith(currentAddress: value)));

  // ── Tenant preferences step ──────────────────────────────────────────────

  void updateBudget(double value) =>
      emit(state.copyWith(data: state.data.copyWith(budget: value)));

  void updatePreferredLocation(String value) =>
      emit(state.copyWith(data: state.data.copyWith(preferredLocation: value)));

  void selectPropertyType(PropertyType value) =>
      emit(state.copyWith(data: state.data.copyWith(propertyType: value)));

  void setFurnished(bool value) =>
      emit(state.copyWith(data: state.data.copyWith(furnished: value)));

  void setPetsAllowed(bool value) =>
      emit(state.copyWith(data: state.data.copyWith(petsAllowed: value)));

  void setNonSmoker(bool value) =>
      emit(state.copyWith(data: state.data.copyWith(nonSmoker: value)));

  void setParkingNeeded(bool value) =>
      emit(state.copyWith(data: state.data.copyWith(parkingNeeded: value)));

  void setWifiRequired(bool value) =>
      emit(state.copyWith(data: state.data.copyWith(wifiRequired: value)));

  void updateGenderPreference(String value) =>
      emit(state.copyWith(data: state.data.copyWith(genderPreference: value)));

  /// Toggles a lifestyle preference on or off.
  void toggleLifestyle(LifestylePreference value) {
    final next = Set<LifestylePreference>.from(state.data.lifestyles);
    if (!next.add(value)) next.remove(value);
    emit(state.copyWith(data: state.data.copyWith(lifestyles: next)));
  }

  // ── Landlord account step ─────────────────────────────────────────────────

  void updateFullName(String value) =>
      emit(state.copyWith(data: state.data.copyWith(fullName: value)));

  // ── Landlord business step ────────────────────────────────────────────────

  void updateBusinessName(String value) =>
      emit(state.copyWith(data: state.data.copyWith(businessName: value)));

  void updateBusinessAddress(String value) =>
      emit(state.copyWith(data: state.data.copyWith(businessAddress: value)));

  void updateYearsOfExperience(String value) =>
      emit(state.copyWith(data: state.data.copyWith(yearsOfExperience: value)));

  // ── Landlord property step ────────────────────────────────────────────────

  void updatePropertyName(String value) =>
      emit(state.copyWith(data: state.data.copyWith(propertyName: value)));

  void updatePropertyAddress(String value) =>
      emit(state.copyWith(data: state.data.copyWith(propertyAddress: value)));

  void updateMonthlyRent(String value) =>
      emit(state.copyWith(data: state.data.copyWith(monthlyRent: value)));

  void updateNumberOfRooms(String value) =>
      emit(state.copyWith(data: state.data.copyWith(numberOfRooms: value)));

  void updatePropertyDescription(String value) =>
      emit(state.copyWith(data: state.data.copyWith(propertyDescription: value)));

  // ── Landlord ideal-tenant step ────────────────────────────────────────────

  void updateMinAge(String value) =>
      emit(state.copyWith(data: state.data.copyWith(minAge: value)));

  void updateMaxAge(String value) =>
      emit(state.copyWith(data: state.data.copyWith(maxAge: value)));

  void updatePreferredOccupation(String value) =>
      emit(state.copyWith(data: state.data.copyWith(preferredOccupation: value)));

  void updateMaxOccupants(String value) =>
      emit(state.copyWith(data: state.data.copyWith(maxOccupants: value)));

  void updateIncomeRange(String value) =>
      emit(state.copyWith(data: state.data.copyWith(incomeRange: value)));

  void setSmokingAllowed(bool value) =>
      emit(state.copyWith(data: state.data.copyWith(smokingAllowed: value)));

  void setParkingAvailable(bool value) =>
      emit(state.copyWith(data: state.data.copyWith(parkingAvailable: value)));

  void setStudentFriendly(bool value) =>
      emit(state.copyWith(data: state.data.copyWith(studentFriendly: value)));

  void setFamilyFriendly(bool value) =>
      emit(state.copyWith(data: state.data.copyWith(familyFriendly: value)));
}
