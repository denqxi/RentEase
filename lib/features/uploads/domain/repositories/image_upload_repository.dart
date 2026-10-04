import '../entities/uploaded_image.dart';

/// Picks and uploads images. Implementations throw [ImageUploadException]
/// with user-facing messages.
abstract class ImageUploadRepository {
  /// Returns a local file path, or null if the user cancelled.
  Future<String?> pick(ImageKind kind, PickSource source);

  /// Uploads one image per call.
  Future<UploadedImage> upload(ImageKind kind, String path);
}
