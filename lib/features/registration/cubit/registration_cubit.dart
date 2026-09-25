import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/mock_data.dart';
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
  RegistrationCubit({this.onComplete}) : super(const RegistrationState());

  final ValueChanged<UserRole>? onComplete;

  static const List<RegistrationStep> _tenantOrder = <RegistrationStep>[
    RegistrationStep.role,
    RegistrationStep.account,
    RegistrationStep.checkEmail,
    RegistrationStep.about,
    RegistrationStep.preferences,
  ];

  static const List<RegistrationStep> _landlordOrder = <RegistrationStep>[
    RegistrationStep.role,
    RegistrationStep.landlordAccount,
    RegistrationStep.checkEmail,
    RegistrationStep.business,
    RegistrationStep.property,
    RegistrationStep.idealTenant,
  ];

  List<RegistrationStep> get _order =>
      state.data.role == UserRole.landlord ? _landlordOrder : _tenantOrder;

  // ── Navigation ───────────────────────────────────────────────────────────

  /// Advances to the next step in the flow, or triggers onComplete on the final step.
  void next() {
    if (state.data.role == UserRole.guest) return;
    final index = _order.indexOf(state.step);
    if (index < _order.length - 1) {
      emit(state.copyWith(step: _order[index + 1]));
    } else {
      final role = state.data.role ?? UserRole.tenant;
      MockData.registerAccount(
        email: state.data.email,
        password: state.data.password,
        role: role == UserRole.landlord ? 'owner' : 'tenant',
        name: role == UserRole.landlord
            ? state.data.fullName
            : '${state.data.firstName} ${state.data.lastName}'.trim(),
      );
      onComplete?.call(role);
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

  void updateGender(String value) =>
      emit(state.copyWith(data: state.data.copyWith(gender: value)));

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

  void selectPropertyType(PropertyType type) =>
      emit(state.copyWith(data: state.data.copyWith(propertyType: type)));

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

  void toggleLifestyle(LifestylePreference pref) {
    final current = Set<LifestylePreference>.from(state.data.lifestyles);
    if (current.contains(pref)) {
      current.remove(pref);
    } else {
      current.add(pref);
    }
    emit(state.copyWith(data: state.data.copyWith(lifestyles: current)));
  }

  // ── Landlord account step ────────────────────────────────────────────────

  void updateFullName(String value) =>
      emit(state.copyWith(data: state.data.copyWith(fullName: value)));

  void updateLandlordEmail(String value) =>
      emit(state.copyWith(data: state.data.copyWith(email: value)));

  void updateLandlordPhone(String value) =>
      emit(state.copyWith(data: state.data.copyWith(phone: value)));

  void updateLandlordPassword(String value) =>
      emit(state.copyWith(data: state.data.copyWith(password: value)));

  // ── Business step ────────────────────────────────────────────────────────

  void updateBusinessName(String value) =>
      emit(state.copyWith(data: state.data.copyWith(businessName: value)));

  void updateBusinessAddress(String value) =>
      emit(state.copyWith(data: state.data.copyWith(businessAddress: value)));

  void updateYearsOfExperience(String value) =>
      emit(state.copyWith(data: state.data.copyWith(yearsOfExperience: value)));

  // ── Property step ────────────────────────────────────────────────────────

  void updatePropertyName(String value) =>
      emit(state.copyWith(data: state.data.copyWith(propertyName: value)));

  void updatePropertyAddress(String value) =>
      emit(state.copyWith(data: state.data.copyWith(propertyAddress: value)));

  void updateMonthlyRent(String value) =>
      emit(state.copyWith(data: state.data.copyWith(monthlyRent: value)));

  void updateNumberOfRooms(String value) =>
      emit(state.copyWith(data: state.data.copyWith(numberOfRooms: value)));

  void selectLandlordPropertyType(PropertyType type) =>
      emit(state.copyWith(data: state.data.copyWith(propertyType: type)));

  void updatePropertyDescription(String value) =>
      emit(state.copyWith(data: state.data.copyWith(propertyDescription: value)));

  // ── Ideal tenant step ────────────────────────────────────────────────────

  void updateMinAge(String value) =>
      emit(state.copyWith(data: state.data.copyWith(minAge: value)));

  void updateMaxAge(String value) =>
      emit(state.copyWith(data: state.data.copyWith(maxAge: value)));

  void updatePreferredOccupation(String value) => emit(
        state.copyWith(data: state.data.copyWith(preferredOccupation: value)),
      );

  void updateMaxOccupants(String value) =>
      emit(state.copyWith(data: state.data.copyWith(maxOccupants: value)));

  void updateIncomeRange(String value) =>
      emit(state.copyWith(data: state.data.copyWith(incomeRange: value)));

  void setLandlordPetsAllowed(bool value) =>
      emit(state.copyWith(data: state.data.copyWith(petsAllowed: value)));

  void setSmokingAllowed(bool value) =>
      emit(state.copyWith(data: state.data.copyWith(smokingAllowed: value)));

  void setParkingAvailable(bool value) =>
      emit(state.copyWith(data: state.data.copyWith(parkingAvailable: value)));

  void setStudentFriendly(bool value) =>
      emit(state.copyWith(data: state.data.copyWith(studentFriendly: value)));

  void setFamilyFriendly(bool value) =>
      emit(state.copyWith(data: state.data.copyWith(familyFriendly: value)));

  void updateLandlordGenderPreference(String value) =>
      emit(state.copyWith(data: state.data.copyWith(genderPreference: value)));
}
