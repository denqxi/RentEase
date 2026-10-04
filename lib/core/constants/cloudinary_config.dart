/// Cloudinary settings for UNSIGNED client uploads.
///
/// Fill the placeholders below from the Cloudinary console. Never put the API
/// secret in the app: unsigned uploads only need the cloud name and an
/// unsigned upload preset.
///
/// Create two unsigned presets (Settings > Upload > Upload presets):
///  * property photos: allow only image formats, set a max file size and an
///    incoming transformation (e.g. `c_limit,w_1280`) to cap storage.
///  * verification documents: same, but prefer delivery type
///    "authenticated"/"private" (see the security caveat in the README/PR:
///    unsigned + public delivery means anyone with the URL can view the file).
class CloudinaryConfig {
  const CloudinaryConfig._();

  /// Console dashboard > "Cloud name".
  static const String cloudName = 'hytcbwuo';

  /// Unsigned preset used for property photos.
  static const String propertyPhotoPreset = 'rentease_property_photos';

  /// Unsigned preset used for owner verification documents.
  static const String documentPreset = 'rentease_verification_docs';

  static const String propertyPhotoFolder = 'rentease/properties';
  static const String documentFolder = 'rentease/verification';

  /// Client-side size cap, checked after the picker has resized/compressed.
  static const int maxPropertyPhotoBytes = 5 * 1024 * 1024;
  static const int maxDocumentBytes = 8 * 1024 * 1024;

  /// Picker downscaling. Photos: 1280px @ 70. Documents stay legible: 1600 @ 80.
  static const double propertyPhotoMaxWidth = 1280;
  static const int propertyPhotoQuality = 70;
  static const double documentMaxWidth = 1600;
  static const int documentQuality = 80;

  static const int maxPropertyPhotos = 5;
  static const int documentCount = 3;

  /// ID and ownership document are required; the business permit (third
  /// slot) is optional.
  static const int requiredDocumentCount = 2;

  static const Duration uploadTimeout = Duration(seconds: 60);

  static Uri get uploadUri =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  static bool get isConfigured =>
      !cloudName.startsWith('YOUR_') &&
      !propertyPhotoPreset.startsWith('YOUR_') &&
      !documentPreset.startsWith('YOUR_');
}
