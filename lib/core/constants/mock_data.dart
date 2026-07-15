/// All static development data for the prototype.
///
/// Field names mirror the Firestore data dictionary (RENTEASE_FIREBASE.MD)
/// so screens can later swap MockData for real repository reads without
/// renaming keys:
///   properties  → `properties` collection (+ tenant-side `matches` fields:
///                 bScore, tenantCi, tenantRank)
///   tenants     → `users` + `tenantProfiles` (+ owner-side `matches` fields:
///                 ownerCi, ownerRank)
///   inquiries   → `inquiries` collection (stage, status)
///   tenantRatings → `ratings` collection (stars, review)
/// Keys that have no schema equivalent are presentation-only and marked
/// `// UI-only` — they are derived or formatted server-side later.
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
  static const String ownerInitials = 'MR';

  static final List<Map<String, dynamic>> properties = [
    {
      'propertyId': 'bh001',
      'title': 'Sunshine Boarding House',
      'address': 'Matina, Davao City',
      'monthlyRent': 3800,
      'distance': 0.4, // schema: matches.distanceKm
      'amenityScore': 8,
      'tenantCi': 0.86,
      'tenantRank': 1,
      'isVerified': true,
      'verifiedSince': 'Mar 12, 2025', // UI-only
      'allowedGender': 'Female only',
      'smokingAllowed': false,
      'petsAllowed': false,
      'curfewHours': 22,
      'depositAmount': 3800,
      'advanceMonths': 1,
      'ownerName': 'Maria Reyes', // UI-only — joined from users
      'ownerInitials': 'MR', // UI-only
      'memberSince': 'Jan 2025', // UI-only
      'propertyCount': 3, // schema: ownerProfiles.propertyCount
      'amenityList': ['WiFi', 'Water', 'Study desk', 'Ref', 'CCTV', 'Laundry', 'Kitchen', 'Electric fan'],
      'bScore': 1,
      'isOutsidePreference': false, // UI-only — session filter flag
      'vacancyStatus': 'available', // schema: properties.vacancyStatus
      'isAvailable': true,
      'latitude': 7.0668, // schema: location GeoPoint
      'longitude': 125.6034,
    },
    {
      'propertyId': 'bh002',
      'title': 'BlueSky Dormitory',
      'address': 'Ecoland, Davao City',
      'monthlyRent': 4200,
      'distance': 1.1, // schema: matches.distanceKm
      'amenityScore': 6,
      'tenantCi': 0.72,
      'tenantRank': 2,
      'isVerified': false,
      'allowedGender': 'Female only',
      'smokingAllowed': false,
      'petsAllowed': false,
      'curfewHours': 21,
      'depositAmount': 4200,
      'advanceMonths': 1,
      'ownerName': 'Ana Santos', // UI-only
      'ownerInitials': 'AS', // UI-only
      'memberSince': 'Mar 2025', // UI-only
      'propertyCount': 1, // schema: ownerProfiles.propertyCount
      'amenityList': ['WiFi', 'AC', 'Water', 'Electricity', 'Laundry', 'Study desk'],
      'bScore': 1,
      'isOutsidePreference': false, // UI-only
      'vacancyStatus': 'pending', // schema: properties.vacancyStatus
      'isAvailable': false,
      'latitude': 7.0585,
      'longitude': 125.6103,
    },
    {
      'propertyId': 'bh003',
      'title': 'Sunrise Manor',
      'address': 'Buhangin, Davao City',
      'monthlyRent': 5500,
      'distance': 4.2, // schema: matches.distanceKm
      'amenityScore': 12,
      // No tenantCi/tenantRank — bScore = 0 removes it from the TOPSIS pool.
      'isVerified': true,
      'verifiedSince': 'Mar 12, 2025', // UI-only
      'allowedGender': 'Female only',
      'smokingAllowed': false,
      'petsAllowed': false,
      'curfewHours': 23,
      'depositAmount': 5500,
      'advanceMonths': 2,
      'ownerName': 'Maria Reyes', // UI-only
      'ownerInitials': 'MR', // UI-only
      'memberSince': 'Jan 2025', // UI-only
      'propertyCount': 3, // schema: ownerProfiles.propertyCount
      'amenityList': [
        'WiFi', 'AC', 'Parking', 'Laundry', 'Water', 'Electricity',
        'Study desk', 'Ref', 'Kitchen', 'CCTV',
        'Electric fan', 'Furnished room',
      ],
      'bScore': 0,
      'isOutsidePreference': false, // UI-only
      'budgetExcess': 1000, // UI-only — why Layer 2 failed
      'distanceExcess': 1.2, // UI-only — why Layer 2 failed
      'vacancyStatus': 'available', // schema: properties.vacancyStatus
      'isAvailable': true,
      'latitude': 7.1063,
      'longitude': 125.6291,
    },
    {
      'propertyId': 'bh004',
      'title': 'Green Leaf Boarding House',
      'address': 'Matina Crossing, Davao City',
      'monthlyRent': 4400,
      'distance': 2.6, // schema: matches.distanceKm
      'amenityScore': 7,
      'tenantCi': 0.58,
      'tenantRank': 3,
      'isVerified': true,
      'verifiedSince': 'Mar 12, 2025', // UI-only
      'allowedGender': 'Female only',
      'smokingAllowed': false,
      'petsAllowed': false,
      'curfewHours': 22,
      'depositAmount': 4400,
      'advanceMonths': 1,
      'ownerName': 'Maria Reyes', // UI-only
      'ownerInitials': 'MR', // UI-only
      'memberSince': 'Jan 2025', // UI-only
      'propertyCount': 3, // schema: ownerProfiles.propertyCount
      'amenityList': ['WiFi', 'Water', 'Laundry', 'Study desk', 'Kitchen', 'CCTV', 'Electric fan'],
      'bScore': 1, // passes saved constraints — only the session override flags it
      'isOutsidePreference': true, // UI-only — session filter flag
      'budgetExcess': 400, // UI-only — vs session override, not saved budget
      'distanceExcess': 0.6, // UI-only — vs session override
      'vacancyStatus': 'available', // schema: properties.vacancyStatus
      'isAvailable': true,
      'latitude': 7.0712,
      'longitude': 125.5981,
    },
  ];

  static final List<Map<String, dynamic>> tenants = [
    {
      'userId': 't001',
      'name': 'Maria Santos', // UI-only — the demo tenant, mirrored on both sides
      'initials': 'MS', // UI-only
      'gender': 'Female',
      'occupation': 'USEP Student', // schema: tenantProfiles.occupation
      'school': 'University of Southeastern Philippines', // schema: tenantProfiles.school
      'maxBudget': 4500,
      'intendedStay': 6,
      'isSmoker': false,
      'hasPet': false,
      'ownerCi': 0.91,
      'ownerRank': 1,
      'bScore': 1,
      'moveIn': 'Aug 1, 2026', // schema: tenantProfiles.moveInDate formatted
      'emergencyContact': 'Rosa Santos — 09171234567', // schema: tenantProfiles.emergencyContact
      'profileCompleteness': 1.0,
      'credibilityScore': 0.9,
    },
    {
      'userId': 't002',
      'name': 'Jana Ramos', // UI-only
      'initials': 'JR', // UI-only
      'gender': 'Female',
      'occupation': 'ADDU Student', // schema: tenantProfiles.occupation
      'school': 'Ateneo de Davao University', // schema: tenantProfiles.school
      'maxBudget': 4000,
      'intendedStay': 12,
      'isSmoker': false,
      'hasPet': false,
      'ownerCi': 0.78,
      'ownerRank': 2,
      'bScore': 1,
      'moveIn': 'Jul 15, 2026', // schema: tenantProfiles.moveInDate formatted
      'emergencyContact': 'Pedro Ramos — 09189876543', // schema: tenantProfiles.emergencyContact
      'profileCompleteness': 0.88,
      'credibilityScore': 0.7,
    },
    {
      'userId': 't003',
      'name': 'Sofia Lim', // UI-only
      'initials': 'SL', // UI-only
      'gender': 'Female',
      'occupation': 'UM Student', // schema: tenantProfiles.occupation
      'school': 'University of Mindanao', // schema: tenantProfiles.school
      'maxBudget': 3500,
      'intendedStay': 3,
      'isSmoker': false,
      'hasPet': false,
      'ownerCi': 0.64,
      'ownerRank': 3,
      'bScore': 1,
      'moveIn': 'Sep 1, 2026', // schema: tenantProfiles.moveInDate formatted
      'emergencyContact': 'Linda Lim — 09201112233', // schema: tenantProfiles.emergencyContact
      'profileCompleteness': 0.75,
      'credibilityScore': 0.5,
    },
  ];

  static final List<Map<String, dynamic>> inquiries = [
    {
      'inquiryId': 'inq001',
      'propertyName': 'Sunshine Boarding House', // UI-only — joined from properties
      'propertyInitials': 'SB', // UI-only
      'ownerName': 'Maria Reyes', // UI-only
      'ownerInitials': 'MR', // UI-only
      'stage': 1,
      'status': 'Waiting for owner response',
      'date': 'Jun 24, 2026', // UI-only — createdAt formatted
      'isOwnerVerified': true, // UI-only — joined from ownerProfiles
    },
    {
      'inquiryId': 'inq002',
      'propertyName': 'BlueSky Dormitory', // UI-only
      'propertyInitials': 'BD', // UI-only
      'ownerName': 'Ana Santos', // UI-only
      'ownerInitials': 'AS', // UI-only
      'stage': 2,
      'status': 'Chat is open',
      'date': 'Jun 22, 2026', // UI-only
      'isOwnerVerified': false, // UI-only
    },
  ];

  static final List<Map<String, dynamic>> ownerInquiries = [
    {
      'inquiryId': 'oinq001',
      'tenantName': 'Maria Santos', // UI-only — mirrors tenant-side inq001
      'tenantInitials': 'MS', // UI-only
      'propertyName': 'Sunshine Boarding House', // UI-only
      'tenantCiSnapshot': 0.91,
      'stage': 1,
      'gender': 'Female',
      'school': 'USEP', // UI-only
      'moveIn': 'Aug 1, 2026', // schema: tenantProfiles.moveInDate formatted
      'stay': '6 months', // UI-only — tenantProfiles.intendedStay formatted
      'maxBudget': 4500,
      'isSmoker': false,
      'hasPet': false,
      'groupSize': 1,
      'emergencyContact': 'Rosa Santos — 09171234567', // schema: tenantProfiles.emergencyContact
      'passesAllRules': true, // UI-only — pScore == 1
    },
    {
      'inquiryId': 'oinq002',
      'tenantName': 'Jana Ramos', // UI-only
      'tenantInitials': 'JR', // UI-only
      'propertyName': 'Sunshine Boarding House', // UI-only
      'tenantCiSnapshot': 0.78,
      'stage': 2,
      'gender': 'Female',
      'school': 'ADDU', // UI-only
      'moveIn': 'Jul 15, 2026', // schema: tenantProfiles.moveInDate formatted
      'stay': '12 months', // UI-only
      'maxBudget': 4000,
      'isSmoker': false,
      'hasPet': false,
      'groupSize': 1,
      'emergencyContact': 'Pedro Ramos — 09189876543', // schema: tenantProfiles.emergencyContact
      'passesAllRules': true, // UI-only
    },
  ];

  /// Searchable Davao City places for the POI search bar (mock geocoder).
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

  /// Named areas used to mock reverse-geocoding of an arbitrary map tap.
  static const List<Map<String, dynamic>> davaoAreas = [
    {'name': 'Matina', 'lat': 7.0660, 'lng': 125.6030},
    {'name': 'Ecoland', 'lat': 7.0580, 'lng': 125.6100},
    {'name': 'Buhangin', 'lat': 7.1060, 'lng': 125.6290},
    {'name': 'Toril', 'lat': 7.0210, 'lng': 125.4990},
    {'name': 'Poblacion', 'lat': 7.0800, 'lng': 125.6150},
    {'name': 'Mintal', 'lat': 7.0850, 'lng': 125.5090},
    {'name': 'Bajada', 'lat': 7.0910, 'lng': 125.6120},
  ];

  /// Resolved inquiries (tenant side) — shown in the Inquiries "Resolved"
  /// tab. May reference properties that are no longer listed.
  static final List<Map<String, dynamic>> tenantResolvedInquiries = [
    {
      'propertyInitials': 'GL',
      'propertyName': 'Green Leaf Boarding House',
      'ownerName': 'Maria Reyes',
      'status': 'Booked',
      'date': 'Feb 3, 2026',
    },
    {
      'propertyInitials': 'CM',
      'propertyName': 'Casa Mia Dormitory',
      'ownerName': 'Pedro Alvarez',
      'status': 'Declined',
      'date': 'Jan 20, 2026',
    },
  ];

  /// Resolved inquiries (owner side) — history log of past decisions.
  static final List<Map<String, dynamic>> ownerInquiryHistory = [
    {
      // Not in the Find Tenants pool — already resolved.
      'tenantName': 'Nica Torres',
      'tenantInitials': 'NT',
      'propertyName': 'Sunshine Boarding House',
      'status': 'Booked',
      'date': 'Jun 10, 2026',
    },
    {
      'tenantName': 'Carla Mendoza',
      'tenantInitials': 'CM',
      'propertyName': 'Sunshine Boarding House',
      'status': 'Declined',
      'date': 'May 28, 2026',
    },
    {
      'tenantName': 'Liza Fernandez',
      'tenantInitials': 'LF',
      'propertyName': 'Sunshine Boarding House',
      'status': 'Accepted',
      'date': 'May 15, 2026',
    },
  ];

  /// Ratings left by previous landlords about a tenant (owner-facing).
  /// Mirrors the `ratings` collection: stars, review.
  static final List<Map<String, dynamic>> tenantRatings = [
    {
      'landlordName': 'Ana Reyes', // UI-only — joined from users via raterId
      'stars': 5,
      'date': 'Apr 2025', // UI-only — createdAt formatted
      'review': 'Paid rent on time every month and kept the room clean. '
          'Would gladly accept her again.',
    },
    {
      'landlordName': 'Juan dela Cruz', // UI-only
      'stars': 4,
      'date': 'Nov 2024', // UI-only
      'review': 'Quiet and respectful of house rules. Occasionally late '
          'with utility share but always settled it.',
    },
  ];

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

  // ── Inquiry lifecycle (mock Cloud Functions) ─────────────────────────────
  // These helpers keep the tenant view and the owner view of the same
  // inquiry in sync, so the full two-phase flow can be simulated live:
  // send → Phase 1 → accept/decline → Phase 2 chat → booked → rating.

  /// "Today" for records created during a demo session.
  static const String demoToday = 'Jul 3, 2026';

  /// Tenant sends a Phase 1 inquiry for [property]. Creates the tenant-side
  /// record and, when the property belongs to the demo owner, mirrors it
  /// into the owner's inbox. Returns false if one already exists.
  static bool sendInquiry(Map<String, dynamic> property) {
    final title = property['title'] as String;
    if (inquiries.any((q) => q['propertyName'] == title)) return false;

    final initials = title
        .split(' ')
        .take(2)
        .map((w) => w.substring(0, 1))
        .join()
        .toUpperCase();
    inquiries.insert(0, {
      'inquiryId': 'inq${100 + inquiries.length}',
      'propertyName': title,
      'propertyInitials': initials,
      'ownerName': property['ownerName'],
      'ownerInitials': property['ownerInitials'],
      'stage': 1,
      'status': 'Waiting for owner response',
      'date': demoToday,
      'isOwnerVerified': property['isVerified'],
    });

    if (property['ownerName'] == ownerName) {
      ownerInquiries.insert(0, {
        'inquiryId': 'oinq${100 + ownerInquiries.length}',
        'tenantName': tenantName,
        'tenantInitials': tenantInitials,
        'propertyName': title,
        'tenantCiSnapshot': 0.91,
        'stage': 1,
        'gender': 'Female',
        'school': 'USEP',
        'moveIn': 'Aug 1, 2026',
        'stay': '6 months',
        'maxBudget': 4500,
        'isSmoker': false,
        'hasPet': false,
        'groupSize': 1,
        'emergencyContact': 'Rosa Santos — 09171234567',
        'passesAllRules': true,
      });
    }
    return true;
  }

  /// Owner accepts — unlocks Phase 2 chat on both sides.
  static void acceptInquiry(Map<String, dynamic> ownerInquiry) {
    ownerInquiry['stage'] = 2;
    final t = _tenantInquiryFor(ownerInquiry);
    if (t != null) {
      t['stage'] = 2;
      t['status'] = 'Chat is open';
    }
  }

  /// Owner declines — resolves the inquiry on both sides.
  static void declineInquiry(Map<String, dynamic> ownerInquiry) {
    _resolveInquiry(ownerInquiry, 'Declined');
  }

  /// Owner marks the tenant as booked — resolves the inquiry on both sides.
  static void bookInquiry(Map<String, dynamic> ownerInquiry) {
    _resolveInquiry(ownerInquiry, 'Booked');
  }

  static void _resolveInquiry(Map<String, dynamic> ownerInquiry, String status) {
    ownerInquiries.remove(ownerInquiry);
    ownerInquiryHistory.insert(0, {
      'tenantName': ownerInquiry['tenantName'],
      'tenantInitials': ownerInquiry['tenantInitials'],
      'propertyName': ownerInquiry['propertyName'],
      'status': status,
      'date': demoToday,
    });
    final t = _tenantInquiryFor(ownerInquiry);
    if (t != null) {
      inquiries.remove(t);
      tenantResolvedInquiries.insert(0, {
        'propertyInitials': t['propertyInitials'],
        'propertyName': t['propertyName'],
        'ownerName': t['ownerName'],
        'status': status,
        'date': demoToday,
      });
    }
  }

  // ── Temporary accounts (in-memory, reset on app restart) ─────────────────

  /// Accounts usable on the Sign In screen. Registration appends here, so a
  /// freshly created account can immediately sign in. Roles: tenant | owner.
  static final List<Map<String, String>> accounts = [
    {
      'email': 'maria@rentease.ph',
      'password': 'RentEase@2026',
      'role': 'tenant',
      'name': tenantName,
    },
    {
      'email': 'reyes@rentease.ph',
      'password': 'RentEase@2026',
      'role': 'owner',
      'name': ownerName,
    },
  ];

  /// Registers (or replaces) a temporary account created during signup.
  static void registerAccount({
    required String email,
    required String password,
    required String role,
    required String name,
  }) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;
    accounts.removeWhere((a) => a['email'] == normalized);
    accounts.add({
      'email': normalized,
      'password': password,
      'role': role,
      'name': name,
    });
  }

  /// Finds an account by email (case-insensitive), or null.
  static Map<String, String>? findAccount(String email) {
    final normalized = email.trim().toLowerCase();
    for (final a in accounts) {
      if (a['email'] == normalized) return a;
    }
    return null;
  }

  // ── Phase 2 chat (shared between tenant and owner screens) ──────────────

  /// Chat threads keyed by "propertyName|tenantName". Each message is
  /// {'sender': 'tenant' | 'owner' | 'system', 'text': ...}. Both Phase 2
  /// screens read and write the same thread, so a message sent by one role
  /// appears on the other role's screen.
  static final Map<String, List<Map<String, String>>> _chatThreads = {
    'BlueSky Dormitory|$tenantName': [
      {'sender': 'system', 'text': 'Owner accepted your inquiry!'},
      {'sender': 'owner', 'text': 'Kumusta! Yes, available pa ang room. \u{1F60A}'},
    ],
    'Sunshine Boarding House|Jana Ramos': [
      {'sender': 'system', 'text': 'Inquiry accepted. Chat is now open.'},
      {
        'sender': 'tenant',
        'text': "Hello! I'm interested in your boarding house. "
            'Is it still available?',
      },
      {
        'sender': 'owner',
        'text': "Yes it's available! When are you planning to move in?",
      },
    ],
  };

  /// The live message list for one inquiry's chat, created on first access.
  static List<Map<String, String>> chatThread(
      String propertyName, String tenantName) {
    return _chatThreads.putIfAbsent(
      '$propertyName|$tenantName',
      () => [
        {'sender': 'system', 'text': 'Inquiry accepted. Chat is now open.'},
      ],
    );
  }

  /// Appends a message to an inquiry's chat thread.
  static void sendChatMessage({
    required String propertyName,
    required String tenantName,
    required String sender,
    required String text,
  }) {
    chatThread(propertyName, tenantName)
        .add({'sender': sender, 'text': text});
  }

  /// The demo tenant's inquiry matching an owner-side record, if the
  /// owner-side record is from the demo tenant.
  static Map<String, dynamic>? _tenantInquiryFor(
      Map<String, dynamic> ownerInquiry) {
    if (ownerInquiry['tenantName'] != tenantName) return null;
    for (final q in inquiries) {
      if (q['propertyName'] == ownerInquiry['propertyName']) return q;
    }
    return null;
  }

  /// Formats schema `curfewHours` (24h number) for display, e.g. 22 → "10:00 PM".
  static String formatCurfew(num? hours) {
    if (hours == null) return 'No curfew';
    final int h = hours.toInt();
    final int h12 = h % 12 == 0 ? 12 : h % 12;
    final String suffix = h < 12 ? 'AM' : 'PM';
    return '$h12:00 $suffix';
  }
}
