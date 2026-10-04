/// Static option lists and fallbacks that are real app configuration (not
/// test data): the paper's amenity checklist, POI search suggestions, and
/// map/slider defaults used before a user has saved anything.
abstract final class AppOptions {
  /// The fixed 14-item amenity checklist (paper-aligned; drives amenityScore).
  static const List<String> amenities = [
    'WiFi',
    'Air conditioning',
    'Electric fan',
    'Private bathroom',
    'Laundry facility',
    'Kitchen or cooking area',
    'CCTV or security camera',
    'Parking space',
    'Study area or desk',
    'Refrigerator access',
    '24-hour access',
    'Water included in rent',
    'Electricity included in rent',
    'Furnished room',
  ];

  /// Searchable Davao City places for the POI search bar (offline geocoder).
  static const List<Map<String, dynamic>> davaoPlaces = [
    {'name': 'University of Southeastern Philippines (Matina)', 'lat': 7.0707, 'lng': 125.6087, 'type': 'school'},
    {'name': 'Ateneo de Davao University', 'lat': 7.0731, 'lng': 125.6110, 'type': 'school'},
    {'name': 'University of Mindanao (Matina)', 'lat': 7.0633, 'lng': 125.5989, 'type': 'school'},
    {'name': 'UP Mindanao (Mintal)', 'lat': 7.0850, 'lng': 125.5090, 'type': 'school'},
    {'name': 'Holy Cross of Davao College', 'lat': 7.0790, 'lng': 125.6155, 'type': 'school'},
    {'name': 'SM City Davao (Ecoland)', 'lat': 7.0508, 'lng': 125.5962, 'type': 'workplace'},
    {'name': 'Davao Doctors Hospital', 'lat': 7.0682, 'lng': 125.6068, 'type': 'workplace'},
    {'name': 'Abreeza Mall (Bajada)', 'lat': 7.0908, 'lng': 125.6120, 'type': 'workplace'},
  ];

  /// Named areas used for approximate reverse-geocoding of a map tap.
  static const List<Map<String, dynamic>> davaoAreas = [
    {'name': 'Matina', 'lat': 7.0660, 'lng': 125.6030},
    {'name': 'Ecoland', 'lat': 7.0580, 'lng': 125.6100},
    {'name': 'Buhangin', 'lat': 7.1060, 'lng': 125.6290},
    {'name': 'Toril', 'lat': 7.0210, 'lng': 125.4990},
    {'name': 'Poblacion', 'lat': 7.0800, 'lng': 125.6150},
    {'name': 'Mintal', 'lat': 7.0850, 'lng': 125.5090},
    {'name': 'Bajada', 'lat': 7.0910, 'lng': 125.6120},
  ];

  /// Map center when no saved POI/pin exists yet (Davao City, Matina).
  static const double defaultMapLat = 7.0707;
  static const double defaultMapLng = 125.6087;

  /// Label for the "use a typical Davao location" shortcut in POI setup.
  static const String defaultMapLabel =
      'University of Southeastern Philippines, Matina, Davao City';

  /// Session-filter fallbacks when the tenant has no saved profile.
  static const double defaultMaxBudget = 4500;
  static const double defaultMaxDistanceKm = 3.0;
}
