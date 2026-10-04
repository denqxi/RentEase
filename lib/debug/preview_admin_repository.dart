import '../core/firestore/models/models.dart';
import '../features/admin/domain/entities/admin_entities.dart';
import '../features/admin/domain/repositories/admin_repository.dart';

/// In-memory [AdminRepository] with static sample data, for the debug screen
/// viewer and screenshot tests (no Firebase). Writes are accepted and ignored.
class PreviewAdminRepository implements AdminRepository {
  const PreviewAdminRepository();

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Stream<List<VerificationItem>> watchVerifications() => Stream.value([
    const VerificationItem(
      profile: OwnerProfileDoc(
        userId: 'preview-owner-1',
        verificationStatus: 'pending',
      ),
      ownerName: 'Carlos Mendoza',
      ownerEmail: 'carlos@example.com',
    ),
    const VerificationItem(
      profile: OwnerProfileDoc(
        userId: 'preview-owner-2',
        verificationStatus: 'pending',
      ),
      ownerName: 'Rosa Villanueva',
      ownerEmail: 'rosa@example.com',
    ),
  ]);

  @override
  Future<VerificationDocuments> fetchDocuments(String ownerId) async =>
      const VerificationDocuments(
        urls: [
          'https://res.cloudinary.com/demo/image/upload/sample.jpg',
          'https://res.cloudinary.com/demo/image/upload/balloons.jpg',
        ],
        publicIds: ['rentease/docs/gov_id', 'rentease/docs/ownership'],
      );

  @override
  Future<void> approveOwner(String ownerId) async {}

  @override
  Future<void> rejectOwner(String ownerId, {String? reason}) async {}

  @override
  Stream<List<UserDoc>> watchUsers() => Stream.value(const [
    UserDoc(
      userId: 'u1',
      firstName: 'Maria',
      lastName: 'Santos',
      email: 'maria@example.com',
      gender: 'female',
      phone: '',
      role: 'tenant',
      status: 'active',
    ),
    UserDoc(
      userId: 'u2',
      firstName: 'Benito',
      lastName: 'Cruz',
      email: 'benito@example.com',
      gender: 'male',
      phone: '',
      role: 'owner',
      status: 'suspended',
    ),
  ]);

  @override
  Future<void> setUserSuspended(
    String userId, {
    required bool suspended,
  }) async {}

  @override
  Stream<List<AdminPropertyItem>> watchProperties() => Stream.value(const []);

  @override
  Future<void> setPropertyListed(
    String propertyId, {
    required bool listed,
  }) async {}

  @override
  Future<AdminStats> fetchStats() async => AdminStats(
    tenants: 42,
    owners: 9,
    properties: 14,
    activeProperties: 11,
    pendingVerifications: 2,
    inquiries: 20,
    bookings: 3,
    signupsLast7Days: [
      for (var i = 0; i < 7; i++)
        DailyCount(DateTime(2026, 10, 1 + i), (i * 3) % 5 + 1),
    ],
  );

  @override
  Stream<List<AdminLogDoc>> watchRecentLogs({int limit = 5}) =>
      Stream.value(const []);
}
