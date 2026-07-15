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
  /// Schema-aligned: `properties.curfewHours` (24h clock hour, e.g. 22).
  static int curfewHours = 22;
  static int rent = 0;
  static Set<String> amenities = <String>{};
  static double? latitude;
  static double? longitude;

  static void reset() {
    name = '';
    address = '';
    deposit = 0;
    advanceMonths = 1;
    genderPolicy = 'Mixed / Any';
    smokingAllowed = false;
    petsAllowed = false;
    curfewHours = 22;
    rent = 0;
    amenities = <String>{};
    latitude = null;
    longitude = null;
  }
}
