import '../../../../core/constants/app_config.dart';

/// One titled block of the Privacy Notice.
class PrivacySection {
  const PrivacySection(this.title, this.body);

  final String title;
  final String body;
}

/// Plain-language Privacy Notice text (Philippine Data Privacy Act of 2012
/// oriented). Kept out of the widget so it can be reviewed and updated on its
/// own. Keep it in line with SECURITY_REPORT.md (PII inventory) and CLAUDE.md
/// ("Contact Privacy" and "Known Limits").
class PrivacyNoticeContent {
  const PrivacyNoticeContent._();

  static const String title = 'Privacy Notice';

  static const String intro =
      'RentEase is a boarding house matching app for Davao City. This notice '
      'explains what personal data we collect, why, who can see it, and what '
      'you can do about it.';

  static const List<PrivacySection> sections = <PrivacySection>[
    PrivacySection(
      'What we collect',
      'Account: your name, email, phone number and gender.\n'
          'Tenants: school or occupation, budget and housing preferences, the '
          'map pin and address of your school or workplace, ranking '
          'priorities, an optional emergency contact and the listings you '
          'saved.\n'
          'Owners: property details (address, map pin, rent, house rules, '
          'amenities, photos) and, for verification, your government ID, '
          'proof of property ownership and an optional business permit.\n'
          'Activity: inquiries, invitations, chat messages, notifications and '
          'ratings you give or receive.',
    ),
    PrivacySection(
      'Why we use it',
      'To create and secure your account, to match tenants and properties '
          'using compatibility rules and ranking, to let compatible people '
          'contact each other, to verify owners and keep the platform safe, '
          'and to handle reports. We do not sell your data and do not use it '
          'for advertising.',
    ),
    PrivacySection(
      'Who can see what',
      'Your name and gender are visible to signed-in users. Your email and '
          'phone are private. Your phone number is shared with the other '
          'party only after an inquiry or invitation is accepted. Your '
          'emergency contact is never shared. Your map pin, address and '
          'ranking priorities are private to you and the admins. Your budget '
          'and basic preferences are visible to property owners so they can '
          'find compatible tenants. Verification documents are visible to '
          'you and to RentEase admins. Property listings and photos are '
          'visible to other users. Chat messages are visible only to the two '
          'people in the conversation. Ratings are visible to signed-in '
          'users.',
    ),
    PrivacySection(
      'Third parties',
      'Google Firebase (sign-in and database) stores your account and app '
          'data. Cloudinary hosts uploaded images, including verification '
          'documents; those images are delivered over public links that '
          'cannot be guessed, but anyone who has a link can open it. '
          'OpenStreetMap map tiles and Google Fonts are loaded from their '
          'servers, which means your IP address is disclosed to them when '
          'you use maps or when fonts are downloaded.',
    ),
    PrivacySection(
      'How long we keep it',
      'We keep your data while your account exists. When you delete your '
          'account your profile, preferences, saved listings, matches, '
          'notifications and (for owners) listings and verification records '
          'are deleted. Inquiry and chat records shared with another user '
          'are kept for that user, and your name is shown there as "Deleted '
          'user". Ratings you gave are kept. Images already uploaded to '
          'Cloudinary cannot be removed by the app; we remove them manually '
          'within ${AppConfig.cloudinaryRemovalDays} days of your request.',
    ),
    PrivacySection(
      'Your rights',
      'You have the right to be informed, to access your data, to correct '
          'it, to object to its processing, to ask for its erasure or '
          'blocking, and to receive a copy of it (data portability). You can '
          'edit most details in the app. For access, portability or any '
          'other request, email us at the address below.',
    ),
    PrivacySection(
      'How to delete your account',
      'Open Profile and choose "Delete my account". You will be asked for '
          'your password and to type DELETE. Deletion cannot be undone.',
    ),
    PrivacySection(
      'Minors',
      'RentEase is for people aged 18 and above. By signing up you confirm '
          'that you are at least 18 years old.',
    ),
  ];

  static const String contactHeading = 'Contact';

  static const String contactBody =
      'For privacy questions or requests, email '
      '${AppConfig.privacyContactEmail}. You may also complain to the '
      'National Privacy Commission (privacy.gov.ph).';
}
