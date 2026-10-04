import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:rentease/features/auth/data/repositories/auth_repository_impl.dart';

class _FbUser implements fb.User {
  @override
  String get uid => 'u1';
  @override
  String? get email => 'a@b.com';
  @override
  bool get emailVerified => true;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeRemote implements AuthRemoteDataSource {
  _FakeRemote(this.doc);

  UserDoc? doc;
  bool failMigration = false;
  int migrations = 0;
  int emergencyMigrations = 0;
  bool failEmergency = false;
  int prefsMigrations = 0;
  bool failPrefs = false;
  UserDoc? createdDoc;
  UserContactDoc? createdContact;

  @override
  fb.User? get currentFirebaseUser => _FbUser();

  @override
  Future<UserDoc?> fetchUserDoc(String uid) async => doc;

  @override
  Future<void> migrateLegacyContact(UserDoc d) async {
    migrations++;
    if (failMigration) throw Exception('permission-denied');
    // What the real batch does: the public doc loses its contact keys.
    doc = UserDoc.fromMap(d.userId, {
      'firstName': d.firstName,
      'lastName': d.lastName,
      'gender': d.gender,
      'role': d.role,
      'status': d.status,
    });
  }

  @override
  Future<void> migrateLegacyEmergencyContact(String uid) async {
    emergencyMigrations++;
    if (failEmergency) throw Exception('permission-denied');
  }

  @override
  Future<void> migrateLegacyTenantPrefs(String uid) async {
    prefsMigrations++;
    if (failPrefs) throw Exception('permission-denied');
  }

  @override
  Future<void> createUserDoc(UserDoc d, {required UserContactDoc contact}) async {
    createdDoc = d;
    createdContact = contact;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

UserDoc _legacy() => UserDoc.fromMap('u1', {
  'firstName': 'Maria',
  'lastName': 'Santos',
  'gender': 'female',
  'role': 'tenant',
  'status': 'active',
  'phone': '09171234567',
  'email': 'maria@example.com',
});

void main() {
  group('UserDoc privacy', () {
    test('toMap never contains email or phone', () {
      final map = _legacy().toMap();
      expect(map.containsKey('email'), isFalse);
      expect(map.containsKey('phone'), isFalse);
    });

    test('legacy docs are detected, clean docs are not', () {
      expect(_legacy().hasLegacyContact, isTrue);
      expect(
        UserDoc.fromMap('u', {'role': 'tenant'}).hasLegacyContact,
        isFalse,
      );
      // Empty-string leftovers still count as legacy keys to delete.
      expect(
        UserDoc.fromMap('u', {'phone': ''}).hasLegacyContact,
        isTrue,
      );
    });

    test('withContact merges private values and keeps the rest', () {
      final u = UserDoc.fromMap('u', {
        'role': 'owner',
        'firstName': 'A',
      }).withContact(email: 'x@y.z');
      expect(u.email, 'x@y.z');
      expect(u.phone, '');
      expect(u.role, 'owner');
    });
  });

  group('sign-up and self-migration', () {
    test('sign-up style user doc carries contact only in the private doc', () async {
      final remote = _FakeRemote(null);
      await remote.createUserDoc(
        const UserDoc(
          userId: 'u1',
          firstName: 'A',
          lastName: 'B',
          gender: 'f',
          role: 'tenant',
          status: 'active',
        ),
        contact: const UserContactDoc(phone: '0917', email: 'a@b.com'),
      );
      expect(remote.createdDoc!.toMap().containsKey('phone'), isFalse);
      expect(remote.createdContact!.phone, '0917');
    });

    test('sign-in/app start migrates a legacy doc once (idempotent)', () async {
      final remote = _FakeRemote(_legacy());
      final repo = AuthRepositoryImpl(remote: remote);

      final user = await repo.currentUser();
      expect(user!.role, 'tenant');
      expect(remote.migrations, 1);
      expect(remote.doc!.hasLegacyContact, isFalse);

      await repo.currentUser();
      await repo.currentUser();
      expect(remote.migrations, 1); // already clean: nothing more to do
    });

    test('tenants also migrate a legacy emergency contact; owners do not', () async {
      final tenant = _FakeRemote(
        UserDoc.fromMap('u1', {'role': 'tenant', 'status': 'active'}),
      );
      await AuthRepositoryImpl(remote: tenant).currentUser();
      expect(tenant.emergencyMigrations, 1);

      final owner = _FakeRemote(
        UserDoc.fromMap('u1', {'role': 'owner', 'status': 'active'}),
      );
      await AuthRepositoryImpl(remote: owner).currentUser();
      expect(owner.emergencyMigrations, 0);
    });

    test('a failing emergency-contact migration never blocks login', () async {
      final remote = _FakeRemote(
        UserDoc.fromMap('u1', {'role': 'tenant', 'status': 'active'}),
      )..failEmergency = true;
      final user = await AuthRepositoryImpl(remote: remote).currentUser();
      expect(user, isNotNull);
    });

    test('tenants also migrate the legacy map pin + weights; owners do not', () async {
      final tenant = _FakeRemote(
        UserDoc.fromMap('u1', {'role': 'tenant', 'status': 'active'}),
      );
      await AuthRepositoryImpl(remote: tenant).currentUser();
      expect(tenant.prefsMigrations, 1);

      final owner = _FakeRemote(
        UserDoc.fromMap('u1', {'role': 'owner', 'status': 'active'}),
      );
      await AuthRepositoryImpl(remote: owner).currentUser();
      expect(owner.prefsMigrations, 0);
    });

    test('a failing prefs migration never blocks login', () async {
      final remote = _FakeRemote(
        UserDoc.fromMap('u1', {'role': 'tenant', 'status': 'active'}),
      )..failPrefs = true;
      final user = await AuthRepositoryImpl(remote: remote).currentUser();
      expect(user, isNotNull);
      expect(user!.role, 'tenant');
    });

    test('UserContactDoc round-trips emergencyContact', () {
      final doc = UserContactDoc.fromMap({'emergencyContact': 'Rosa'});
      expect(doc.emergencyContact, 'Rosa');
      expect(doc.toMap()['emergencyContact'], 'Rosa');
      expect(const UserContactDoc().toMap().containsKey('emergencyContact'), isFalse);
    });

    test('clean accounts are never touched', () async {
      final remote = _FakeRemote(
        UserDoc.fromMap('u1', {'role': 'owner', 'status': 'active'}),
      );
      await AuthRepositoryImpl(remote: remote).currentUser();
      expect(remote.migrations, 0);
    });

    test('a failing migration never blocks login and retries next time', () async {
      final remote = _FakeRemote(_legacy())..failMigration = true;
      final repo = AuthRepositoryImpl(remote: remote);

      final user = await repo.currentUser();
      expect(user, isNotNull);
      expect(user!.role, 'tenant');
      expect(remote.migrations, 1);

      remote.failMigration = false;
      await repo.currentUser();
      expect(remote.migrations, 2);
      expect(remote.doc!.hasLegacyContact, isFalse);
    });
  });
}
