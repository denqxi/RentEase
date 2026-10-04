import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/owner_onboarding/cubit/owner_onboarding_cubit.dart';
import 'package:rentease/features/owner_onboarding/domain/repositories/owner_onboarding_repository.dart';
import 'package:rentease/features/uploads/domain/entities/uploaded_image.dart';

class _FakeRepo implements OwnerOnboardingRepository {
  List<UploadedImage>? submitted;

  @override
  Future<String> submitForVerification(
    String uid, {
    List<UploadedImage> documents = const [],
  }) async {
    submitted = documents;
    return 'pending';
  }

  @override
  Stream<String> watchVerificationStatus(String uid) => const Stream.empty();

  @override
  Future<String> createProperty(PropertyDoc property) async => 'p1';
}

List<UploadedImage> _docs(int n) => [
  for (var i = 0; i < n; i++) UploadedImage(url: 'https://x/$i', publicId: 'id$i'),
];

void main() {
  group('submitForVerification', () {
    test('accepts two documents (business permit omitted)', () async {
      final repo = _FakeRepo();
      final cubit = OwnerOnboardingCubit(repository: repo);
      await cubit.submitForVerification('u1', documents: _docs(2));
      expect(cubit.state.status, OwnerOnboardingStatus.saved);
      expect(repo.submitted, hasLength(2));
    });

    test('accepts three documents', () async {
      final repo = _FakeRepo();
      final cubit = OwnerOnboardingCubit(repository: repo);
      await cubit.submitForVerification('u1', documents: _docs(3));
      expect(cubit.state.status, OwnerOnboardingStatus.saved);
      expect(repo.submitted, hasLength(3));
    });

    test('rejects fewer than two documents without touching the repo', () async {
      final repo = _FakeRepo();
      final cubit = OwnerOnboardingCubit(repository: repo);
      await cubit.submitForVerification('u1', documents: _docs(1));
      expect(cubit.state.status, OwnerOnboardingStatus.failure);
      expect(repo.submitted, isNull);
    });
  });
}
