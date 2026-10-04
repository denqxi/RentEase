import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/models/models.dart';
import '../../../uploads/domain/entities/uploaded_image.dart';
import '../../domain/repositories/owner_onboarding_repository.dart';
import '../datasources/owner_onboarding_remote_datasource.dart';

class OwnerOnboardingRepositoryImpl implements OwnerOnboardingRepository {
  OwnerOnboardingRepositoryImpl({OwnerOnboardingRemoteDataSource? remote})
    : _remote = remote ?? OwnerOnboardingRemoteDataSource();

  final OwnerOnboardingRemoteDataSource _remote;

  @override
  Future<String> submitForVerification(
    String uid, {
    List<UploadedImage> documents = const [],
  }) => _guard(
    () => _remote.submitForVerification(uid, documents: documents),
  );

  @override
  Stream<String> watchVerificationStatus(String uid) =>
      _remote.watchVerificationStatus(uid);

  @override
  Future<String> createProperty(PropertyDoc property) =>
      _guard(() => _remote.createProperty(property));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (e) {
      throw Exception(_messageFor(e));
    }
  }

  String _messageFor(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return "You don't have permission to save this listing. Your account "
            'may have been rejected — please contact support.';
      case 'unavailable':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
