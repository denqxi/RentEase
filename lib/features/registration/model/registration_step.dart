/// The ordered steps of the registration flow.
enum RegistrationStep {
  /// Choose Tenant or Landlord.
  role,

  // ── Tenant path ────────────────────────────────────────────────────────────
  /// Personal details (tenant step 1/3).
  account,
  /// Email verification gate shown right after account creation.
  checkEmail,
  /// Background info (tenant step 2/3).
  about,
  /// Rental preferences (tenant step 3/3).
  preferences,

  // ── Landlord path ──────────────────────────────────────────────────────────
  /// Personal details (landlord step 1/4).
  landlordAccount,
  /// Business profile (landlord step 2/4).
  business,
  /// Property listing (landlord step 3/4).
  property,
  /// Ideal tenant criteria (landlord step 4/4).
  idealTenant,

  /// Completion / "You're all set" screen.
  success;

  /// 1-based position within the progress bar, or null for steps that don't
  /// show a progress bar (role, success).
  int? get formStepNumber => switch (this) {
        RegistrationStep.account => null,
        RegistrationStep.about => 2,
        RegistrationStep.preferences => 3,
        RegistrationStep.landlordAccount => null,
        RegistrationStep.business => 2,
        RegistrationStep.property => 3,
        RegistrationStep.idealTenant => 4,
        _ => null,
      };

  /// Whether this step displays the progress header.
  bool get showsProgress => formStepNumber != null;
}
