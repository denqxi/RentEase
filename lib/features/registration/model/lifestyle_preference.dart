/// Lifestyle preferences a tenant can select (multiple allowed).
enum LifestylePreference {
  quietEnvironment('Quiet environment'),
  familyFriendly('Family-friendly'),
  studentFriendly('Student-friendly'),
  workingProfessionals('Working professionals');

  const LifestylePreference(this.label);

  /// Human-readable label shown in the chip.
  final String label;
}
