/// Deployment-specific settings that the project owners must fill in.
class AppConfig {
  const AppConfig._();

  /// PLACEHOLDER - replace with the real privacy / data-protection contact
  /// mailbox before release. Shown in the Privacy Notice.
  static const String privacyContactEmail = 'privacy@rentease.example';

  /// How many days the team takes to remove Cloudinary images after an
  /// erasure request (stated in the Privacy Notice).
  static const int cloudinaryRemovalDays = 30;
}
