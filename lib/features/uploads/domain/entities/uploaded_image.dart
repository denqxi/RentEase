import 'package:equatable/equatable.dart';

/// Result of a successful image upload: the delivery URL and the id needed to
/// manage/delete the asset later.
class UploadedImage extends Equatable {
  const UploadedImage({required this.url, required this.publicId});

  final String url;
  final String publicId;

  @override
  List<Object?> get props => [url, publicId];
}

enum ImageKind { propertyPhoto, verificationDocument }

enum PickSource { gallery, camera }

/// An upload/pick failure with a message that is safe to show to the user.
class ImageUploadException implements Exception {
  const ImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
