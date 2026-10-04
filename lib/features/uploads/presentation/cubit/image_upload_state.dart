part of 'image_upload_cubit.dart';

enum SlotStatus { empty, uploading, success, failure }

class UploadSlot extends Equatable {
  const UploadSlot({
    this.status = SlotStatus.empty,
    this.localPath,
    this.image,
    this.error,
  });

  final SlotStatus status;

  /// Local file shown as the thumbnail while/after uploading.
  final String? localPath;
  final UploadedImage? image;
  final String? error;

  @override
  List<Object?> get props => [status, localPath, image, error];
}

class ImageUploadState extends Equatable {
  const ImageUploadState({
    required this.slots,
    required this.minRequired,
    this.requiredSlots,
  });

  final List<UploadSlot> slots;
  final int minRequired;

  /// When set, exactly these slot indexes must be uploaded (the rest are
  /// optional) and [minRequired] is ignored. Null keeps the count-based rule.
  final Set<int>? requiredSlots;

  int get uploadedCount =>
      slots.where((s) => s.status == SlotStatus.success).length;
  bool get isUploading => slots.any((s) => s.status == SlotStatus.uploading);
  bool get hasFailure => slots.any((s) => s.status == SlotStatus.failure);

  /// Enough successful uploads and nothing in flight or broken.
  bool get isReady {
    if (isUploading || hasFailure) return false;
    final required = requiredSlots;
    if (required == null) return uploadedCount >= minRequired;
    return required.every(
      (i) => i < slots.length && slots[i].status == SlotStatus.success,
    );
  }

  List<UploadedImage> get images => [
    for (final s in slots)
      if (s.status == SlotStatus.success) s.image!,
  ];

  @override
  List<Object?> get props => [slots, minRequired, requiredSlots];
}
