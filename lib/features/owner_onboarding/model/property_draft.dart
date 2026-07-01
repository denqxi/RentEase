/// In-memory scratch space threading data across the "Add property" wizard
/// steps. Committed to [MockData.properties] on the final step, then reset —
/// never persisted, matching the session-only nature of this prototype.
class NewPropertyDraft {
  static String name = '';
  static String address = '';
  static int deposit = 0;
  static int advanceMonths = 1;
  static String genderPolicy = 'Mixed / Any';
  static bool smokingAllowed = false;
  static bool petsAllowed = false;
  static String curfew = '10:00 PM';
  static int rent = 0;
  static Set<String> amenities = <String>{};

  static void reset() {
    name = '';
    address = '';
    deposit = 0;
    advanceMonths = 1;
    genderPolicy = 'Mixed / Any';
    smokingAllowed = false;
    petsAllowed = false;
    curfew = '10:00 PM';
    rent = 0;
    amenities = <String>{};
  }
}
