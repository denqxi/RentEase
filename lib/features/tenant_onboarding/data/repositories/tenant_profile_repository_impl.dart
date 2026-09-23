import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/models/tenant_profile_doc.dart';
import '../../domain/repositories/tenant_profile_repository.dart';
import '../datasources/tenant_profile_remote_datasource.dart';

class TenantProfileRepositoryImpl implements TenantProfileRepository {
  TenantProfileRepositoryImpl({TenantProfileRemoteDataSource? remote})
    : _remote = remote ?? TenantProfileRemoteDataSource();

  final TenantProfileRemoteDataSource _remote;

  @override
  Future<void> saveProfile(TenantProfileDoc profile) async {
    try {
      await _remote.setProfile(profile);
    } on FirebaseException catch (e) {
      throw Exception(_messageFor(e));
    }
  }

  @override
  Future<TenantProfileDoc?> fetchProfile(String uid) async {
    try {
      return await _remote.getProfile(uid);
    } on FirebaseException catch (e) {
      throw Exception(_messageFor(e));
    }
  }

  String _messageFor(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return "You don't have permission to save this profile. "
            'Make sure you are signed in.';
      case 'unavailable':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Could not save your profile. Please try again.';
    }
  }
}
