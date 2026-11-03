import 'package:shared_preferences/shared_preferences.dart';

/// Text for the create-listing wizard in English or Tagalog (Filipino).
///
/// Scoped to this wizard only; the rest of the app is English. English and
/// Tagalog sit side by side so a native speaker can review them in one place.
/// The Tagalog is a first draft and should be checked by the team before
/// release. Stored values (amenities, gender policy, property type) stay in
/// English; only what is displayed changes.
class ListingStrings {
  const ListingStrings(this.tagalog);

  final bool tagalog;

  String _t(String en, String tl) => tagalog ? tl : en;

  // ── Language toggle ────────────────────────────────────────────────────
  String get languageEnglish => 'English';
  String get languageTagalog => 'Tagalog';

  // ── Buttons ────────────────────────────────────────────────────────────
  String get continueLabel => _t('Continue', 'Magpatuloy');
  String get postListing => _t('Post Listing', 'I-post ang Listing');
  String get posting => _t('Posting...', 'Pino-post...');
  String get posted =>
      _t('Your listing is now posted.', 'Naka-post na ang iyong listing.');

  // ── Step headers (title, subtitle) ─────────────────────────────────────
  (String, String) get headerRentalType => (
    _t('What are you renting out?', 'Ano ang iyong pinauupahan?'),
    _t(
      'Choose what tenants can rent from you.',
      'Piliin kung ano ang puwedeng upahan ng mga tenant.',
    ),
  );
  (String, String) get headerRoomDetails => (
    _t('Tell us about your room', 'Ikuwento ang iyong kuwarto'),
    _t(
      'Choose the property where your room is located.',
      'Piliin ang property kung saan matatagpuan ang iyong kuwarto.',
    ),
  );
  (String, String) get headerPlaceDetails => (
    _t('Tell us about your place', 'Ikuwento ang iyong lugar'),
    _t(
      'Add the details tenants will see.',
      'Ilagay ang mga detalyeng makikita ng mga tenant.',
    ),
  );
  (String, String) get headerHouseRules => (
    _t('Set your house rules', 'Itakda ang mga patakaran sa bahay'),
    _t(
      'Let tenants know what is allowed.',
      'Ipaalam sa mga tenant kung ano ang pinapayagan.',
    ),
  );
  (String, String) get headerRent => (
    _t('Set the rent and capacity', 'Itakda ang upa at kapasidad'),
    _t(
      'How much is the rent, and how many people can stay?',
      'Magkano ang upa kada buwan, at ilang tao ang puwedeng tumira?',
    ),
  );
  (String, String) get headerAmenities => (
    _t('What does your place have?', 'Ano ang mayroon sa iyong lugar?'),
    _t(
      'Select everything tenants can use.',
      'Piliin lahat ng puwedeng gamitin ng mga tenant.',
    ),
  );
  (String, String) get headerReview => (
    _t('Check your listing', 'Suriin ang iyong listing'),
    _t(
      'Make sure everything is correct before posting.',
      'Siguraduhing tama ang lahat bago i-post.',
    ),
  );

  // ── Step tips (title, body) ────────────────────────────────────────────
  String get tipHowTo => _t('How to fill this in', 'Paano ito sagutan');
  String get tipRoomBody => _t(
    'Pick the building first, the room uses its address and map pin. Give '
        'each room its own name, like Room 101, and add clear photos of the '
        'room itself.',
    'Piliin muna ang building. Gagamitin ng kuwarto ang address at pin nito '
        'sa mapa. Bigyan ng sariling pangalan ang bawat kuwarto, halimbawa '
        'Room 101, at maglagay ng malinaw na litrato ng kuwarto.',
  );
  String get tipPlaceBody => _t(
    'Use the name tenants know your place by. Drop the pin on the exact '
        'entrance, since distance to a tenant\'s school or work is measured '
        'from it. Use a bright photo as the cover.',
    'Gamitin ang pangalang kilala ng mga tao sa iyong lugar. Ilagay ang pin '
        'sa mapa mismo sa pasukan, dahil dito sinusukat ang layo papunta sa '
        'paaralan o trabaho ng tenant. Gumamit ng maliwanag na litrato bilang '
        'cover.',
  );
  String get tipRulesTitle => _t(
    'These rules decide who sees your listing',
    'Ang mga patakarang ito ang magpapasya kung sino ang makakakita',
  );
  String get tipRulesBody => _t(
    'Tenants who don\'t fit your rules (for example, smokers when smoking '
        'is off) are not matched, so you only get inquiries from tenants who '
        'fit.',
    'Ang mga tenant na hindi tugma sa iyong patakaran (halimbawa, '
        'naninigarilyo pero bawal ang paninigarilyo) ay hindi mama-match, '
        'kaya ang magtatanong lang ay ang mga tugma.',
  );
  String get tipRentTitle => _t(
    'Rent and capacity affect matching',
    'Nakakaapekto ang upa at kapasidad sa matching',
  );
  String get tipRentBody => _t(
    'Tenants whose maximum budget is below your rent, or whose group is '
        'bigger than your limit, won\'t see this listing.',
    'Ang mga tenant na mas mababa ang budget kaysa sa iyong upa, o mas '
        'marami ang grupo kaysa sa iyong limit, ay hindi makakakita ng '
        'listing na ito.',
  );
  String get tipAmenitiesTitle => _t(
    'Only select what tenants can really use',
    'Piliin lang ang talagang magagamit ng tenant',
  );
  String get tipAmenitiesBody => _t(
    'Each amenity raises your ranking for tenants who care about amenities. '
        'Listing ones you don\'t have leads to bad reviews.',
    'Bawat amenity ay nagpapataas ng iyong ranking para sa mga tenant na '
        'nagpapahalaga sa amenities. Kapag naglagay ka ng wala naman, '
        'puwedeng magresulta sa masamang review.',
  );
  String get tipReviewTitle => _t('Almost done', 'Malapit nang matapos');
  String get tipReviewBody => _t(
    'Tap back to fix anything. After posting, you can still edit or hide '
        'this listing from your properties.',
    'Pindutin ang back para baguhin ang kahit ano. Pagkatapos i-post, '
        'puwede mo pa ring i-edit o itago ang listing na ito mula sa iyong '
        'mga property.',
  );

  // ── Step 1: rental type ────────────────────────────────────────────────
  String get entirePlace => _t(
    'Entire Place (Single Unit)',
    'Buong Lugar (Isang Unit)',
  );
  String get entirePlaceDesc => _t(
    'Rent the whole property under one single price.',
    'Ipaupa ang buong property sa iisang presyo.',
  );
  String get entirePlaceBadgePrice => _t('1 Fixed Price', '1 Presyo');
  String get entirePlaceBadgeTenant =>
      _t('1 Group / Tenant', '1 Grupo / Umuupa');

  String get aRoom => _t(
    'By Room',
    'Bawat Kuwarto',
  );
  String get aRoomDesc => _t(
    'Rooms with separate prices and amenities.',
    'Mga kuwartong may sariling presyo at amenities.',
  );
  String get aRoomBadgeRates => _t('Different Room Rates', 'Iba-ibang Presyo');
  String get aRoomBadgeAmenities =>
      _t('Separate Amenities', 'Sariling Amenities');

  // Tutorial strings
  String get tutorialEntirePlaceTitle => _t('Entire Place', 'Buong Lugar');
  String get tutorialEntirePlaceBody => _t(
    '• Use this for single-unit properties rented out as a whole with one fixed price.\n\n• A multi-room property can also be listed here as long as all rooms share the exact same price, rules, and amenities.',
    '• Gamitin ito para sa mga property na pinapaupahan nang buo sa iisang presyo.\n\n• Puwede rin ito sa property na may maraming kuwarto basta pare-pareho ang presyo, patakaran, at amenities ng lahat ng kuwarto.',
  );

  String get tutorialRoomTitle => _t('A Room', 'Isang Kuwarto');
  String get tutorialRoomBody => _t(
    '• Use this for properties with multiple rooms that have different prices, rules, capacities, or amenities (e.g. boarding houses or dorms).\n\n• You can add and manage each room individually under this building.',
    '• Gamitin ito para sa mga property na may maraming kuwarto na magkakaiba ang presyo, patakaran, kapasidad, o amenities (hal. boarding house o dorm).\n\n• Puwede mong idagdag at pamahalaan ang bawat kuwarto nang paisa-isa sa ilalim ng building na ito.',
  );

  String get tutorialNext => _t('Next (1/2) →', 'Susunod (1/2) →');
  String tutorialNextStep(int current, int total) =>
      _t('Next ($current/$total) →', 'Susunod ($current/$total) →');
  String get tutorialGotIt => _t('Got it!', 'Nakuha ko!');
  String get tutorialSkip => _t('Skip', 'Laktawan');
  String get addMoreLaterTitle =>
      _t('You can add more later', 'Puwede kang magdagdag mamaya');
  String get addMoreLaterBody => _t(
    'You can create another listing if you have more rooms or properties.',
    'Puwede kang gumawa ng ibang listing kung marami kang kuwarto o '
        'property.',
  );

  // ── Step 2: details ────────────────────────────────────────────────────
  String get propertyName => _t('Property name', 'Pangalan ng property');
  String get propertyNameHint =>
      _t('e.g. Sunshine Apartment', 'halimbawa: Sunshine Apartment');
  String get propertyType => _t('Property type', 'Uri ng property');
  String get propertyTypeHint =>
      _t('Select property type', 'Piliin ang uri ng property');
  String get addPhotos => _t('Add photos', 'Magdagdag ng litrato');
  String get addRoomPhotos =>
      _t('Add room photos', 'Magdagdag ng litrato ng kuwarto');
  String photosCaption(int max) => _t(
    'Add 1 to $max photos. The first is the cover.',
    'Maglagay ng 1 hanggang $max na litrato. Ang una ang magiging cover.',
  );
  String get loadingProperties => _t(
    'Loading your properties...',
    'Nilo-load ang iyong mga property...',
  );
  String get selectProperty =>
      _t('Select a property', 'Pumili ng property');
  String get propertyNameRoomCaption => _t(
    'The name of your building, boarding house, or dorm.',
    'Ang pangalan ng iyong building, boarding house, o dorm.',
  );
  String get addNewProperty =>
      _t('+ Add New Property', '+ Magdagdag ng Bagong Property');
  String get roomName =>
      _t('Room name or number', 'Pangalan o numero ng kuwarto');
  String get roomNameCaption => _t(
    'The specific room label your tenants will see (e.g. Room 101 or Room A).',
    'Ang partikular na numero o pangalan ng kuwarto (hal. Room 101 o Room A).',
  );
  String get roomNameHint => _t('e.g. Room 101', 'halimbawa: Room 101');
  String roomNameTaken(String building) => _t(
    'This room name is already used in $building.',
    'Ginagamit na ang pangalang ito ng kuwarto sa $building.',
  );
  String get listingName => _t('Listing name', 'Pangalan ng listing');
  String get listingNameCaption => _t(
    'Automatically combines your building and room name so tenants easily recognize it.',
    'Awtomatikong pinagsasama ang building at kuwarto para madaling makita ng mga umuupa.',
  );
  String get listingNameAuto => _t(
    'Created from the property and room name',
    'Gagawin mula sa pangalan ng property at kuwarto',
  );

  // ── Step 3: house rules ────────────────────────────────────────────────
  String get deposit => _t('Security deposit (₱)', 'Deposito (₱)');
  String get depositCaption => _t(
    'Paid once when the tenant moves in.',
    'Isang beses binabayaran pagpasok ng tenant.',
  );
  String get advance =>
      _t('Advance rent (months)', 'Advance na upa (buwan)');
  String get advanceCaption => _t(
    'Months of rent paid upfront before moving in.',
    'Ilang buwan ng upa ang babayaran bago lumipat.',
  );
  String get whoCanRent =>
      _t('Who can rent?', 'Sino ang puwedeng umupa?');
  String get selectHint => _t('Select...', 'Pumili...');
  String get anyone => _t('Anyone', 'Kahit sino');
  String get maleOnly => _t('Male only', 'Lalaki lang');
  String get femaleOnly => _t('Female only', 'Babae lang');
  String get smokingAllowed =>
      _t('Smoking allowed', 'Pinapayagan ang paninigarilyo');
  String get petsAllowed =>
      _t('Pets allowed', 'Pinapayagan ang alagang hayop');
  String get curfew => _t('Curfew', 'Curfew');
  String get noCurfew => _t('No curfew', 'Walang curfew');

  // ── Step 4: rent ───────────────────────────────────────────────────────
  String get monthlyRent => _t('Monthly rent (₱)', 'Upa kada buwan (₱)');
  String get maxOccupants => _t(
    'Maximum number of occupants',
    'Pinakamaraming puwedeng tumira',
  );
  String get availableForRent =>
      _t('Available for rent', 'Bakante para upahan');
  String get availableHelper => _t(
    'Turn off if tenants cannot move in yet.',
    'I-off kung hindi pa puwedeng lumipat ang mga tenant.',
  );

  // ── Step 5: amenities ──────────────────────────────────────────────────
  String amenitiesSelected(int n, int total) =>
      _t('$n of $total selected', '$n sa $total ang napili');

  String amenityGroup(String group) => !tagalog
      ? group
      : switch (group) {
          'Comfort & Internet' => 'Ginhawa at Internet',
          'Bathroom & Facilities' => 'Banyo at Pasilidad',
          'Safety & Convenience' => 'Kaligtasan at Kaginhawaan',
          'Bills Included' => 'Kasama na ang Bayarin',
          _ => group,
        };

  /// Display label for a stored amenity value (values stay English).
  String amenity(String value) => !tagalog
      ? value
      : switch (value) {
          'Air conditioning' => 'Aircon',
          'Electric fan' => 'Electric fan',
          'Furnished room' => 'Kuwartong may gamit',
          'Private bathroom' => 'Sariling banyo',
          'Laundry facility' => 'Labahan',
          'Kitchen or cooking area' => 'Kusina o lutuan',
          'Refrigerator access' => 'Puwedeng gamitin ang ref',
          'CCTV or security camera' => 'CCTV o security camera',
          'Parking space' => 'Paradahan',
          'Study area or desk' => 'Lugar-aralan o mesa',
          '24-hour access' => 'Bukas 24 oras',
          'Water included in rent' => 'Kasama na ang tubig sa upa',
          'Electricity included in rent' => 'Kasama na ang kuryente sa upa',
          _ => value,
        };

  // ── Step 6: review ─────────────────────────────────────────────────────
  String get reviewListing => _t('Listing', 'Listing');
  String get reviewRentalType => _t('Rental type', 'Uri ng paupahan');
  String get reviewProperty => _t('Property', 'Property');
  String get reviewAddress => _t('Address', 'Address');
  String get reviewRoomType => _t(
    'A Room — a room in a boarding house, dorm, or shared home.',
    'Isang Kuwarto — kuwarto sa boarding house, dorm, o shared na bahay.',
  );
  String get reviewPlaceType => _t(
    'Entire Place — a whole house, apartment, or condo.',
    'Buong Lugar — buong bahay, apartment, o condo.',
  );
  String get reviewPhotos => _t('Photos', 'Mga litrato');
  String get noPhotos => _t('No photos yet', 'Wala pang litrato');
  String get reviewHouseRules =>
      _t('House rules', 'Mga patakaran sa bahay');
  String get reviewDeposit => _t('Security deposit', 'Deposito');
  String get reviewAdvance => _t('Advance rent', 'Advance na upa');
  String months(int n) => _t('$n month(s)', '$n buwan');
  String get reviewWhoCanRent =>
      _t('Who can rent', 'Sino ang puwedeng umupa');
  String get reviewSmoking => _t('Smoking', 'Paninigarilyo');
  String get reviewPets => _t('Pets', 'Alagang hayop');
  String get allowed => _t('Allowed', 'Pinapayagan');
  String get notAllowed => _t('Not allowed', 'Bawal');
  String get reviewRent => _t('Rent & occupants', 'Upa at titira');
  String get reviewMonthlyRent => _t('Monthly rent', 'Upa kada buwan');
  String get reviewMaxOccupants =>
      _t('Max occupants', 'Pinakamaraming titira');
  String get reviewAvailability => _t('Availability', 'Kalagayan');
  String get notAvailable => _t('Not available', 'Hindi bakante');
  String get reviewAmenities => _t('Amenities', 'Amenities');
  String get noneSelected => _t('None selected', 'Walang napili');
}

/// Remembers the owner's language choice for the create-listing wizard on
/// this device.
abstract final class ListingLanguageStore {
  static const _key = 'listing_wizard_tagalog';

  /// Defaults to English if storage can't be read.
  static Future<bool> isTagalog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setTagalog(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {
      // Non-critical: the wizard just opens in English next time.
    }
  }
}

/// Remembers whether the create-listing wizard onboarding tutorials have already
/// been seen on this device so they are shown only once like a true tutorial.
abstract final class ListingTutorialStore {
  static const _rentalTypeTutorialKey = 'listing_wizard_rental_type_tutorial_seen';
  static const _roomTutorialKey = 'listing_wizard_room_tutorial_seen';

  static Future<bool> hasSeenRentalTypeTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rentalTypeTutorialKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markRentalTypeTutorialSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rentalTypeTutorialKey, true);
    } catch (_) {}
  }

  static Future<bool> hasSeenRoomTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_roomTutorialKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markRoomTutorialSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_roomTutorialKey, true);
    } catch (_) {}
  }
}
