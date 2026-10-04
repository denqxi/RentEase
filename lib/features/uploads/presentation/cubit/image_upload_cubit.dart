import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/uploaded_image.dart';
import '../../domain/repositories/image_upload_repository.dart';

part 'image_upload_state.dart';

/// Holds N upload slots for one kind of image. Each slot picks, uploads
/// (one request per image), and can be retried or removed independently.
class ImageUploadCubit extends Cubit<ImageUploadState> {
  ImageUploadCubit({
    required this._repository,
    required this.kind,
    required int slotCount,
    required int minRequired,
    Set<int>? requiredSlots,
    List<UploadedImage> initialImages = const [],
  }) : super(
         ImageUploadState(
           // Already-uploaded images (e.g. an existing listing's photos)
           // fill the first slots as successes; they have no local file.
           slots: List<UploadSlot>.generate(
             slotCount,
             (i) => i < initialImages.length
                 ? UploadSlot(
                     status: SlotStatus.success,
                     image: initialImages[i],
                   )
                 : const UploadSlot(),
           ),
           minRequired: minRequired,
           requiredSlots: requiredSlots,
         ),
       );

  final ImageUploadRepository _repository;
  final ImageKind kind;

  void _setSlot(int i, UploadSlot slot) {
    if (isClosed) return;
    final slots = List<UploadSlot>.of(state.slots)..[i] = slot;
    emit(
      ImageUploadState(
        slots: slots,
        minRequired: state.minRequired,
        requiredSlots: state.requiredSlots,
      ),
    );
  }

  Future<void> pickAndUpload(int i, PickSource source) async {
    if (state.slots[i].status == SlotStatus.uploading) return; // double tap
    try {
      final path = await _repository.pick(kind, source);
      if (path == null) return;
      await _upload(i, path);
    } on ImageUploadException catch (e) {
      _setSlot(i, UploadSlot(status: SlotStatus.failure, error: e.message));
    }
  }

  Future<void> retry(int i) async {
    final slot = state.slots[i];
    if (slot.status != SlotStatus.failure || slot.localPath == null) return;
    await _upload(i, slot.localPath!);
  }

  void remove(int i) {
    if (state.slots[i].status == SlotStatus.uploading) return;
    _setSlot(i, const UploadSlot());
  }

  /// Moves the photo in slot [i] one place earlier (slot 0 is the cover),
  /// swapping with the slot before it. No-op while either is uploading.
  void moveEarlier(int i) {
    if (i <= 0 || i >= state.slots.length) return;
    if (state.slots[i].status == SlotStatus.uploading ||
        state.slots[i - 1].status == SlotStatus.uploading) {
      return;
    }
    final slots = List<UploadSlot>.of(state.slots);
    final tmp = slots[i];
    slots[i] = slots[i - 1];
    slots[i - 1] = tmp;
    emit(
      ImageUploadState(
        slots: slots,
        minRequired: state.minRequired,
        requiredSlots: state.requiredSlots,
      ),
    );
  }

  Future<void> _upload(int i, String path) async {
    _setSlot(i, UploadSlot(status: SlotStatus.uploading, localPath: path));
    try {
      final image = await _repository.upload(kind, path);
      _setSlot(
        i,
        UploadSlot(status: SlotStatus.success, localPath: path, image: image),
      );
    } on ImageUploadException catch (e) {
      _setSlot(
        i,
        UploadSlot(
          status: SlotStatus.failure,
          localPath: path,
          error: e.message,
        ),
      );
    } catch (_) {
      _setSlot(
        i,
        UploadSlot(
          status: SlotStatus.failure,
          localPath: path,
          error: 'Upload failed. Please try again.',
        ),
      );
    }
  }
}
