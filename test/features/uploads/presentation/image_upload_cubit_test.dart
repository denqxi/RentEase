import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/features/uploads/domain/entities/uploaded_image.dart';
import 'package:rentease/features/uploads/domain/repositories/image_upload_repository.dart';
import 'package:rentease/features/uploads/presentation/cubit/image_upload_cubit.dart';

class _FakeRepo implements ImageUploadRepository {
  String? picked = '/tmp/a.jpg';
  Object? uploadError;
  int uploads = 0;

  @override
  Future<String?> pick(ImageKind kind, PickSource source) async => picked;

  @override
  Future<UploadedImage> upload(ImageKind kind, String path) async {
    uploads++;
    final e = uploadError;
    if (e != null) throw e;
    return UploadedImage(url: 'https://x/$uploads', publicId: 'id$uploads');
  }
}

ImageUploadCubit _cubit(_FakeRepo r, {int slots = 3, int min = 1}) =>
    ImageUploadCubit(
      repository: r,
      kind: ImageKind.propertyPhoto,
      slotCount: slots,
      minRequired: min,
    );

void main() {
  test('starts not ready', () {
    expect(_cubit(_FakeRepo()).state.isReady, false);
  });

  test('successful upload makes it ready and exposes images', () async {
    final c = _cubit(_FakeRepo());
    await c.pickAndUpload(0, PickSource.gallery);
    expect(c.state.slots[0].status, SlotStatus.success);
    expect(c.state.isReady, true);
    expect(c.state.images.single.publicId, 'id1');
  });

  test('cancelled pick leaves slot empty', () async {
    final r = _FakeRepo()..picked = null;
    final c = _cubit(r);
    await c.pickAndUpload(0, PickSource.camera);
    expect(c.state.slots[0].status, SlotStatus.empty);
  });

  test('failure blocks readiness; retry recovers; remove clears', () async {
    final r = _FakeRepo()..uploadError = const ImageUploadException('boom');
    final c = _cubit(r);
    await c.pickAndUpload(0, PickSource.gallery);
    expect(c.state.slots[0].error, 'boom');
    expect(c.state.isReady, false);
    r.uploadError = null;
    await c.retry(0);
    expect(c.state.isReady, true);
    c.remove(0);
    expect(c.state.slots[0].status, SlotStatus.empty);
  });

  test('all slots required when minRequired == slotCount', () async {
    final c = _cubit(_FakeRepo(), slots: 2, min: 2);
    await c.pickAndUpload(0, PickSource.gallery);
    expect(c.state.isReady, false);
    await c.pickAndUpload(1, PickSource.gallery);
    expect(c.state.isReady, true);
  });

  group('requiredSlots (optional trailing slot)', () {
    ImageUploadCubit docs(_FakeRepo r) => ImageUploadCubit(
      repository: r,
      kind: ImageKind.verificationDocument,
      slotCount: 3,
      minRequired: 2,
      requiredSlots: {0, 1},
    );

    test('ready with the two required slots; optional slot empty', () async {
      final c = docs(_FakeRepo());
      await c.pickAndUpload(0, PickSource.gallery);
      expect(c.state.isReady, false);
      await c.pickAndUpload(1, PickSource.gallery);
      expect(c.state.isReady, true);
      expect(c.state.images, hasLength(2));
    });

    test('optional slot alone does not satisfy the requirement', () async {
      final c = docs(_FakeRepo());
      await c.pickAndUpload(2, PickSource.gallery);
      await c.pickAndUpload(0, PickSource.gallery);
      expect(c.state.isReady, false);
    });

    test('a failed optional upload blocks submit until removed', () async {
      final r = _FakeRepo();
      final c = docs(r);
      await c.pickAndUpload(0, PickSource.gallery);
      await c.pickAndUpload(1, PickSource.gallery);
      r.uploadError = const ImageUploadException('boom');
      await c.pickAndUpload(2, PickSource.gallery);
      expect(c.state.isReady, false);
      c.remove(2);
      expect(c.state.isReady, true);
    });

    test('all three uploaded is also ready', () async {
      final c = docs(_FakeRepo());
      for (var i = 0; i < 3; i++) {
        await c.pickAndUpload(i, PickSource.gallery);
      }
      expect(c.state.isReady, true);
      expect(c.state.images, hasLength(3));
    });
  });

  test('initialImages seed success slots; moveEarlier reorders', () {
    final c = ImageUploadCubit(
      repository: _FakeRepo(),
      kind: ImageKind.propertyPhoto,
      slotCount: 3,
      minRequired: 1,
      initialImages: const [
        UploadedImage(url: 'u1', publicId: 'p1'),
        UploadedImage(url: 'u2', publicId: 'p2'),
      ],
    );
    expect(c.state.isReady, true);
    expect(c.state.images.map((i) => i.publicId), ['p1', 'p2']);
    c.moveEarlier(1);
    expect(c.state.images.map((i) => i.publicId), ['p2', 'p1']);
    c.moveEarlier(0); // no-op
    expect(c.state.images.first.publicId, 'p2');
  });
}
