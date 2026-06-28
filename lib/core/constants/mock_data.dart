<<<<<<< Updated upstream
/// Static mock data used across all new RentEase screens during prototyping.
class MockData {
  static const String tenantName     = 'Maria Santos';
  static const String tenantInitials = 'MS';
  static const String tenantSchool   = 'USEP — Matina Campus';

  static const String ownerName     = 'Maria Reyes';
=======
class MockData {
  static const String tenantName = 'Maria Santos';
  static const String tenantInitials = 'MS';
  static const String tenantSchool = 'USEP Matina Campus';
  static const String tenantPoi = 'University of Southeastern Philippines, Matina, Davao City';
  static const double tenantPoiLat = 7.0707;
  static const double tenantPoiLng = 125.6087;
  static const double tenantMaxDistance = 3.0;
  static const double tenantMaxBudget = 4500;
  static const String ownerName = 'Maria Reyes';
>>>>>>> Stashed changes
  static const String ownerInitials = 'MR';

  static final List<Map<String, dynamic>> properties = [
    {
      'id': 'bh001',
<<<<<<< Updated upstream
      'name': 'Villa Hazel Dormitory',
      'address': 'Ecoland, Davao City',
      'rent': 3800,
      'distance': 0.8,
      'amenities': 6,
      'ciScore': 0.86,
      'rank': 1,
      'isVerified': true,
=======
      'name': 'Sunshine Boarding House',
      'address': 'Matina, Davao City',
      'rent': 3800,
      'distance': 0.4,
      'amenities': 8,
      'ciScore': 0.86,
      'rank': 1,
      'isVerified': true,
      'verifiedSince': 'Mar 12, 2025',
>>>>>>> Stashed changes
      'allowedGender': 'Female only',
      'smokingAllowed': false,
      'petsAllowed': false,
      'curfew': '10:00 PM',
<<<<<<< Updated upstream
      'depositMonths': 2,
      'advanceMonths': 1,
      'ownerName': 'Aling Nena Villanueva',
      'ownerInitials': 'NV',
      'memberSince': '2022',
      'propertyCount': 3,
      'amenityList': ['WiFi', 'Water', 'Study desk', 'Ref', 'CCTV', 'Laundry'],
      'bScore': 1,
      'isOutsidePreference': false,
    },
    {
      'id': 'bh002',
      'name': 'Sta. Ana Boarding House',
      'address': 'Sta. Ana, Davao City',
      'rent': 4200,
      'distance': 1.4,
      'amenities': 5,
      'ciScore': 0.79,
=======
      'deposit': 3800,
      'advanceMonths': 1,
      'ownerName': 'Maria Reyes',
      'ownerInitials': 'MR',
      'memberSince': 'Jan 2025',
      'propertyCount': 3,
      'amenityList': ['WiFi', 'Water', 'Study desk', 'Ref', 'CCTV', 'Laundry', 'Kitchen', 'Security'],
      'bScore': 1,
      'isOutsidePreference': false,
      'vacancyStatus': 'available',
    },
    {
      'id': 'bh002',
      'name': 'BlueSky Dormitory',
      'address': 'Ecoland, Davao City',
      'rent': 4200,
      'distance': 1.1,
      'amenities': 6,
      'ciScore': 0.72,
>>>>>>> Stashed changes
      'rank': 2,
      'isVerified': false,
      'allowedGender': 'Female only',
      'smokingAllowed': false,
      'petsAllowed': false,
      'curfew': '9:00 PM',
<<<<<<< Updated upstream
      'depositMonths': 1,
      'advanceMonths': 1,
      'ownerName': 'Ana Santos',
      'ownerInitials': 'AS',
      'memberSince': '2023',
      'propertyCount': 1,
      'amenityList': ['WiFi', 'AC', 'Water', 'Electricity', 'Laundry'],
      'bScore': 1,
      'isOutsidePreference': false,
    },
    {
      'id': 'bh003',
      'name': 'Ecoland Deluxe Rooms',
      'address': 'Ecoland, Davao City',
      'rent': 4800,
      'distance': 4.2,
      'amenities': 10,
      'ciScore': 0.91,
      'rank': 3,
=======
      'deposit': 4200,
      'advanceMonths': 1,
      'ownerName': 'Ana Santos',
      'ownerInitials': 'AS',
      'memberSince': 'Mar 2025',
      'propertyCount': 1,
      'amenityList': ['WiFi', 'AC', 'Water', 'Electricity', 'Laundry', 'Study desk'],
      'bScore': 1,
      'isOutsidePreference': false,
      'vacancyStatus': 'pending',
    },
    {
      'id': 'bh003',
      'name': 'Sunrise Manor',
      'address': 'Buhangin, Davao City',
      'rent': 5500,
      'distance': 4.2,
      'amenities': 12,
      'ciScore': 0.91,
      'rank': 1,
>>>>>>> Stashed changes
      'isVerified': true,
      'allowedGender': 'Female only',
      'smokingAllowed': false,
      'petsAllowed': false,
      'curfew': '11:00 PM',
<<<<<<< Updated upstream
      'depositMonths': 2,
      'advanceMonths': 1,
      'ownerName': 'Juan dela Cruz',
      'ownerInitials': 'JC',
      'memberSince': '2021',
      'propertyCount': 5,
      'amenityList': [
        'WiFi', 'AC', 'Parking', 'Laundry', 'Water',
        'Electricity', 'Study desk', 'Ref', 'Kitchen', 'CCTV',
      ],
      'bScore': 0,
      'isOutsidePreference': true,
      'budgetExcess': 0,
      'distanceExcess': 1.2,
=======
      'deposit': 5500,
      'advanceMonths': 2,
      'ownerName': 'Juan dela Cruz',
      'ownerInitials': 'JC',
      'memberSince': 'Feb 2025',
      'propertyCount': 5,
      'amenityList': [
        'WiFi', 'AC', 'Parking', 'Laundry', 'Water', 'Electricity',
        'Study desk', 'Ref', 'Kitchen', 'CCTV', 'Security',
        'Electric fan', 'Furnished room', '24-hour access',
      ],
      'bScore': 0,
      'isOutsidePreference': true,
      'budgetExcess': 1000,
      'distanceExcess': 1.2,
      'vacancyStatus': 'available',
>>>>>>> Stashed changes
    },
  ];

  static final List<Map<String, dynamic>> tenants = [
    {
      'id': 't001',
      'name': 'Maria Andres',
      'initials': 'MA',
      'gender': 'Female',
      'occupation': 'USEP Student',
<<<<<<< Updated upstream
=======
      'school': 'University of Southeastern Philippines',
>>>>>>> Stashed changes
      'budget': 4500,
      'intendedStay': 6,
      'isSmoker': false,
      'hasPet': false,
      'ciScore': 0.91,
      'rank': 1,
      'bScore': 1,
<<<<<<< Updated upstream
=======
      'moveIn': 'Aug 1, 2025',
      'emergencyContact': 'Rosa Andres — 09171234567',
      'profileComplete': 1.0,
      'credibilityScore': 0.9,
>>>>>>> Stashed changes
    },
    {
      'id': 't002',
      'name': 'Jana Ramos',
      'initials': 'JR',
      'gender': 'Female',
      'occupation': 'ADDU Student',
<<<<<<< Updated upstream
=======
      'school': 'Ateneo de Davao University',
>>>>>>> Stashed changes
      'budget': 4000,
      'intendedStay': 12,
      'isSmoker': false,
      'hasPet': false,
      'ciScore': 0.78,
      'rank': 2,
      'bScore': 1,
<<<<<<< Updated upstream
=======
      'moveIn': 'Jul 15, 2025',
      'emergencyContact': 'Pedro Ramos — 09189876543',
      'profileComplete': 0.88,
      'credibilityScore': 0.7,
>>>>>>> Stashed changes
    },
    {
      'id': 't003',
      'name': 'Sofia Lim',
      'initials': 'SL',
      'gender': 'Female',
      'occupation': 'UM Student',
<<<<<<< Updated upstream
=======
      'school': 'University of Mindanao',
>>>>>>> Stashed changes
      'budget': 3500,
      'intendedStay': 3,
      'isSmoker': false,
      'hasPet': false,
      'ciScore': 0.64,
      'rank': 3,
      'bScore': 1,
<<<<<<< Updated upstream
=======
      'moveIn': 'Sep 1, 2025',
      'emergencyContact': 'Linda Lim — 09201112233',
      'profileComplete': 0.75,
      'credibilityScore': 0.5,
>>>>>>> Stashed changes
    },
  ];

  static final List<Map<String, dynamic>> inquiries = [
    {
      'id': 'inq001',
<<<<<<< Updated upstream
      'propertyName': 'Villa Hazel Dormitory',
      'propertyInitials': 'VH',
      'ownerName': 'Aling Nena Villanueva',
      'ownerInitials': 'NV',
=======
      'propertyName': 'Sunshine Boarding House',
      'propertyInitials': 'SB',
      'ownerName': 'Maria Reyes',
      'ownerInitials': 'MR',
>>>>>>> Stashed changes
      'phase': 1,
      'status': 'Waiting for owner response',
      'date': 'Jun 24, 2025',
      'isOwnerVerified': true,
    },
    {
      'id': 'inq002',
<<<<<<< Updated upstream
      'propertyName': 'Sta. Ana Boarding House',
      'propertyInitials': 'SA',
=======
      'propertyName': 'BlueSky Dormitory',
      'propertyInitials': 'BD',
>>>>>>> Stashed changes
      'ownerName': 'Ana Santos',
      'ownerInitials': 'AS',
      'phase': 2,
      'status': 'Chat is open',
      'date': 'Jun 22, 2025',
      'isOwnerVerified': false,
    },
  ];

  static final List<Map<String, dynamic>> ownerInquiries = [
    {
      'id': 'oinq001',
      'tenantName': 'Maria Andres',
      'tenantInitials': 'MA',
      'propertyName': 'Sunshine Boarding House',
      'ciScore': 0.91,
      'phase': 1,
      'gender': 'Female',
      'school': 'USEP',
      'moveIn': 'Aug 1, 2025',
      'stay': '6 months',
      'budget': 4500,
      'isSmoker': false,
      'hasPet': false,
<<<<<<< Updated upstream
=======
      'groupSize': 1,
>>>>>>> Stashed changes
      'emergencyContact': 'Rosa Andres — 09171234567',
      'passesAllRules': true,
    },
    {
      'id': 'oinq002',
      'tenantName': 'Jana Ramos',
      'tenantInitials': 'JR',
      'propertyName': 'Sunshine Boarding House',
      'ciScore': 0.78,
      'phase': 2,
      'gender': 'Female',
      'school': 'ADDU',
      'moveIn': 'Jul 15, 2025',
      'stay': '12 months',
      'budget': 4000,
      'isSmoker': false,
      'hasPet': false,
<<<<<<< Updated upstream
=======
      'groupSize': 1,
>>>>>>> Stashed changes
      'emergencyContact': 'Pedro Ramos — 09189876543',
      'passesAllRules': true,
    },
  ];
<<<<<<< Updated upstream
=======

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
>>>>>>> Stashed changes
}
