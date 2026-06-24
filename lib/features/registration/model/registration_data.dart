import 'package:equatable/equatable.dart';

import 'lifestyle_preference.dart';
import 'property_type.dart';
import 'user_role.dart';

/// All information collected across the registration flow.
///
/// Immutable — use [copyWith] to produce updated copies as the user fills in
/// each step.
class RegistrationData extends Equatable {
  const RegistrationData({
    this.role,
    // Tenant account step.
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.password = '',
    // Tenant about-you step.
    this.age = '',
    this.occupation = '',
    this.monthlyIncome = '',
    this.occupants = '',
    this.currentAddress = '',
    // Tenant preferences step.
    this.budget = 1500,
    this.preferredLocation = 'Downtown',
    this.furnished = true,
    this.nonSmoker = true,
    this.parkingNeeded = true,
    this.wifiRequired = true,
    this.lifestyles = const <LifestylePreference>{},
    // Landlord account step.
    this.fullName = '',
    // Landlord business step.
    this.businessName = '',
    this.businessAddress = '',
    this.yearsOfExperience = '',
    // Landlord property step.
    this.propertyName = '',
    this.propertyAddress = '',
    this.monthlyRent = '',
    this.numberOfRooms = '',
    this.propertyType = PropertyType.apartment,
    this.propertyDescription = '',
    // Landlord ideal-tenant step (also reuses petsAllowed, genderPreference).
    this.minAge = '',
    this.maxAge = '',
    this.preferredOccupation = '',
    this.maxOccupants = '',
    this.incomeRange = 'Any',
    this.petsAllowed = true,
    this.smokingAllowed = false,
    this.parkingAvailable = true,
    this.studentFriendly = true,
    this.familyFriendly = true,
    this.genderPreference = 'No preference',
  });

  // Role.
  final UserRole? role;

  // ── Tenant account step ──────────────────────────────────────────────────
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;

  // ── Tenant about-you step ────────────────────────────────────────────────
  final String age;
  final String occupation;
  final String monthlyIncome;
  final String occupants;
  final String currentAddress;

  // ── Tenant preferences step ──────────────────────────────────────────────
  final double budget;
  final String preferredLocation;
  final bool furnished;
  final bool nonSmoker;
  final bool parkingNeeded;
  final bool wifiRequired;
  final Set<LifestylePreference> lifestyles;

  // ── Landlord account step ─────────────────────────────────────────────────
  final String fullName;

  // ── Landlord business step ────────────────────────────────────────────────
  final String businessName;
  final String businessAddress;
  final String yearsOfExperience;

  // ── Landlord property step ────────────────────────────────────────────────
  final String propertyName;
  final String propertyAddress;
  final String monthlyRent;
  final String numberOfRooms;
  final PropertyType propertyType;
  final String propertyDescription;

  // ── Landlord ideal-tenant step ────────────────────────────────────────────
  final String minAge;
  final String maxAge;
  final String preferredOccupation;
  final String maxOccupants;
  final String incomeRange;
  final bool petsAllowed;
  final bool smokingAllowed;
  final bool parkingAvailable;
  final bool studentFriendly;
  final bool familyFriendly;
  final String genderPreference;

  RegistrationData copyWith({
    UserRole? role,
    // Tenant account.
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? password,
    // Tenant about.
    String? age,
    String? occupation,
    String? monthlyIncome,
    String? occupants,
    String? currentAddress,
    // Tenant preferences.
    double? budget,
    String? preferredLocation,
    bool? furnished,
    bool? nonSmoker,
    bool? parkingNeeded,
    bool? wifiRequired,
    Set<LifestylePreference>? lifestyles,
    // Landlord account.
    String? fullName,
    // Landlord business.
    String? businessName,
    String? businessAddress,
    String? yearsOfExperience,
    // Landlord property.
    String? propertyName,
    String? propertyAddress,
    String? monthlyRent,
    String? numberOfRooms,
    PropertyType? propertyType,
    String? propertyDescription,
    // Landlord ideal tenant.
    String? minAge,
    String? maxAge,
    String? preferredOccupation,
    String? maxOccupants,
    String? incomeRange,
    bool? petsAllowed,
    bool? smokingAllowed,
    bool? parkingAvailable,
    bool? studentFriendly,
    bool? familyFriendly,
    String? genderPreference,
  }) {
    return RegistrationData(
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      age: age ?? this.age,
      occupation: occupation ?? this.occupation,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      occupants: occupants ?? this.occupants,
      currentAddress: currentAddress ?? this.currentAddress,
      budget: budget ?? this.budget,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      furnished: furnished ?? this.furnished,
      nonSmoker: nonSmoker ?? this.nonSmoker,
      parkingNeeded: parkingNeeded ?? this.parkingNeeded,
      wifiRequired: wifiRequired ?? this.wifiRequired,
      lifestyles: lifestyles ?? this.lifestyles,
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      propertyName: propertyName ?? this.propertyName,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      numberOfRooms: numberOfRooms ?? this.numberOfRooms,
      propertyType: propertyType ?? this.propertyType,
      propertyDescription: propertyDescription ?? this.propertyDescription,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      preferredOccupation: preferredOccupation ?? this.preferredOccupation,
      maxOccupants: maxOccupants ?? this.maxOccupants,
      incomeRange: incomeRange ?? this.incomeRange,
      petsAllowed: petsAllowed ?? this.petsAllowed,
      smokingAllowed: smokingAllowed ?? this.smokingAllowed,
      parkingAvailable: parkingAvailable ?? this.parkingAvailable,
      studentFriendly: studentFriendly ?? this.studentFriendly,
      familyFriendly: familyFriendly ?? this.familyFriendly,
      genderPreference: genderPreference ?? this.genderPreference,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        role,
        firstName,
        lastName,
        email,
        phone,
        password,
        age,
        occupation,
        monthlyIncome,
        occupants,
        currentAddress,
        budget,
        preferredLocation,
        furnished,
        nonSmoker,
        parkingNeeded,
        wifiRequired,
        lifestyles,
        fullName,
        businessName,
        businessAddress,
        yearsOfExperience,
        propertyName,
        propertyAddress,
        monthlyRent,
        numberOfRooms,
        propertyType,
        propertyDescription,
        minAge,
        maxAge,
        preferredOccupation,
        maxOccupants,
        incomeRange,
        petsAllowed,
        smokingAllowed,
        parkingAvailable,
        studentFriendly,
        familyFriendly,
        genderPreference,
      ];
}
