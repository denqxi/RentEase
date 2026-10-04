import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/models.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// uid -> display name, so list refreshes do not re-read user docs.
  final Map<String, ({String name, String email})> _people = {};

  static const _listLimit = 500;

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection(name);

  String get _adminId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const AdminException('Please sign in again.');
    return uid;
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AdminException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AdminException(_authMessage(e.code));
    } on FirebaseException catch (e) {
      throw AdminException(switch (e.code) {
        'permission-denied' => 'You do not have permission to do that.',
        'unavailable' || 'deadline-exceeded' =>
          'Network problem. Check your connection and try again.',
        _ => 'Something went wrong. Please try again.',
      });
    }
  }

  String _authMessage(String code) => switch (code) {
    'invalid-email' => 'Enter a valid email address.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Incorrect email or password.',
    'too-many-requests' => 'Too many attempts. Try again later.',
    'network-request-failed' =>
      'Network problem. Check your connection and try again.',
    _ => 'Could not sign in. Please try again.',
  };

  Stream<T> _mapErrors<T>(Stream<T> source) => source.handleError((Object e) {
    if (e is FirebaseException) {
      throw AdminException(
        e.code == 'permission-denied'
            ? 'You do not have permission to view this.'
            : 'Could not load data. Please try again.',
      );
    }
    throw e;
  });

  // ---------------- auth ----------------

  @override
  Future<void> signIn(String email, String password) => _guard(() async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user?.uid;
    final snap = uid == null
        ? null
        : await _col(FirestoreCollections.users).doc(uid).get();
    if (snap == null ||
        !snap.exists ||
        snap.data()?['role'] != 'admin' ||
        (snap.data()?['status'] ?? 'active') == 'suspended') {
      await _auth.signOut();
      throw const AdminException('This account is not an administrator.');
    }
  });

  @override
  Future<void> signOut() => _auth.signOut();

  // ---------------- names ----------------

  Future<void> _loadPeople(Iterable<String> ids) async {
    final missing = ids
        .where((id) => id.isNotEmpty && !_people.containsKey(id))
        .toSet()
        .toList();
    for (var i = 0; i < missing.length; i += 30) {
      final chunk = missing.sublist(
        i,
        i + 30 > missing.length ? missing.length : i + 30,
      );
      final snap = await _col(
        FirestoreCollections.users,
      ).where(FieldPath.documentId, whereIn: chunk).get();
      for (final d in snap.docs) {
        final u = UserDoc.fromSnapshot(d);
        _people[d.id] = (
          name: '${u.firstName} ${u.lastName}'.trim(),
          email: u.email,
        );
      }
    }
    await _loadContacts(ids);
  }

  /// uid -> private contact email ('' when missing or unreadable), cached so
  /// list refreshes do not re-read.
  final Map<String, String> _emails = {};

  String _emailOf(String id, {required String legacy}) {
    final e = _emails[id] ?? '';
    return e.isNotEmpty ? e : legacy;
  }

  /// Admins read `users/{uid}/private/contact` (email + phone are not on the
  /// public users doc). A missing doc or a failed read yields an empty email
  /// rather than failing the whole list.
  Future<void> _loadContacts(Iterable<String> ids) async {
    final missing = ids
        .where((id) => id.isNotEmpty && !_emails.containsKey(id))
        .toSet();
    await Future.wait([
      for (final id in missing)
        () async {
          try {
            final snap = await _col(FirestoreCollections.users)
                .doc(id)
                .collection(FirestoreCollections.userPrivate)
                .doc(FirestoreCollections.userContact)
                .get();
            _emails[id] = UserContactDoc.fromSnapshot(snap).email;
          } catch (_) {
            _emails[id] = '';
          }
        }(),
    ]);
  }

  String _nameOf(String id) {
    final n = _people[id]?.name ?? '';
    return n.isEmpty ? 'Unknown owner' : n;
  }

  // ---------------- verifications ----------------

  @override
  Stream<List<VerificationItem>> watchVerifications() => _mapErrors(
    _col(FirestoreCollections.ownerProfiles)
        .where(
          'verificationStatus',
          whereIn: ['pending', 'verified', 'rejected'],
        )
        .limit(_listLimit)
        .snapshots()
        .asyncMap((snap) async {
          final profiles = snap.docs.map(OwnerProfileDoc.fromSnapshot).toList()
            ..sort((a, b) {
              final x = a.submittedAt?.millisecondsSinceEpoch ?? 0;
              final y = b.submittedAt?.millisecondsSinceEpoch ?? 0;
              return y.compareTo(x);
            });
          await _loadPeople(profiles.map((p) => p.userId));
          return [
            for (final p in profiles)
              VerificationItem(
                profile: p,
                ownerName: _nameOf(p.userId),
                ownerEmail: _emailOf(
                  p.userId,
                  legacy: _people[p.userId]?.email ?? '',
                ),
              ),
          ];
        }),
  );

  @override
  Future<VerificationDocuments> fetchDocuments(String ownerId) =>
      _guard(() async {
        final snap = await _col(FirestoreCollections.ownerProfiles)
            .doc(ownerId)
            .collection(FirestoreCollections.ownerPrivate)
            .doc(FirestoreCollections.ownerPrivateDocuments)
            .get();
        final data = snap.data() ?? const <String, dynamic>{};
        return VerificationDocuments(
          urls: (data['documentUrls'] as List?)?.cast<String>() ?? const [],
          publicIds:
              (data['documentPublicIds'] as List?)?.cast<String>() ?? const [],
        );
      });

  Map<String, dynamic> _log(
    String action,
    String targetId,
    String targetType,
    String? reason,
  ) => AdminLogDoc(
    logId: '',
    adminId: _adminId,
    action: action,
    targetId: targetId,
    targetType: targetType,
    reason: reason ?? '',
  ).toMap();

  @override
  Future<void> approveOwner(String ownerId) => _guard(() async {
    final ref = _col(FirestoreCollections.ownerProfiles).doc(ownerId);
    final current = await ref.get();
    if (current.data()?['verificationStatus'] != 'pending') {
      throw const AdminException('This request is no longer pending.');
    }
    final listings = await _col(
      FirestoreCollections.properties,
    ).where('ownerId', isEqualTo: ownerId).get();

    final batch = _db.batch();
    batch.update(ref, {
      'verificationStatus': 'verified',
      'verifiedAt': FieldValue.serverTimestamp(),
      'rejectionReason': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final p in listings.docs) {
      batch.update(p.reference, {
        'isVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.set(
      _col(FirestoreCollections.adminLogs).doc(),
      _log('approve_owner', ownerId, 'owner', null),
    );
    await batch.commit();
  });

  @override
  Future<void> rejectOwner(String ownerId, {String? reason}) =>
      _guard(() async {
        final ref = _col(FirestoreCollections.ownerProfiles).doc(ownerId);
        final current = await ref.get();
        if (current.data()?['verificationStatus'] != 'pending') {
          throw const AdminException('This request is no longer pending.');
        }
        final trimmed = reason?.trim() ?? '';
        final batch = _db.batch();
        batch.update(ref, {
          'verificationStatus': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
          if (trimmed.isNotEmpty) 'rejectionReason': trimmed,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        batch.set(
          _col(FirestoreCollections.adminLogs).doc(),
          _log('reject_owner', ownerId, 'owner', trimmed),
        );
        await batch.commit();
      });

  // ---------------- users ----------------

  @override
  Stream<List<UserDoc>> watchUsers() => _mapErrors(
    _col(FirestoreCollections.users)
        .where('role', whereIn: ['tenant', 'owner'])
        .limit(_listLimit)
        .snapshots()
        .asyncMap((snap) async {
          final docs = snap.docs.map(UserDoc.fromSnapshot).toList();
          await _loadContacts(docs.map((u) => u.userId));
          final users = [
            for (final u in docs)
              u.withContact(email: _emailOf(u.userId, legacy: u.email)),
          ]..sort((a, b) {
              final x = a.createdAt?.millisecondsSinceEpoch ?? 0;
              final y = b.createdAt?.millisecondsSinceEpoch ?? 0;
              return y.compareTo(x);
            });
          return users;
        }),
  );

  @override
  Future<void> setUserSuspended(String userId, {required bool suspended}) =>
      _guard(() async {
        final batch = _db.batch();
        batch.update(_col(FirestoreCollections.users).doc(userId), {
          'status': suspended ? 'suspended' : 'active',
        });
        batch.set(
          _col(FirestoreCollections.adminLogs).doc(),
          _log(
            suspended ? 'suspend_user' : 'reactivate_user',
            userId,
            'user',
            null,
          ),
        );
        await batch.commit();
      });

  // ---------------- properties ----------------

  @override
  Stream<List<AdminPropertyItem>> watchProperties() => _mapErrors(
    _col(
      FirestoreCollections.properties,
    ).limit(_listLimit).snapshots().asyncMap((snap) async {
      final items = snap.docs
          .map((d) => (PropertyDoc.fromSnapshot(d), d.data()))
          .toList();
      await _loadPeople(items.map((e) => e.$1.ownerId));
      final out =
          [
            for (final (p, raw) in items)
              AdminPropertyItem(
                property: p,
                ownerName: _nameOf(p.ownerId),
                adminUnlisted: raw['adminUnlisted'] as bool? ?? false,
              ),
          ]..sort((a, b) {
            final x = a.property.createdAt?.millisecondsSinceEpoch ?? 0;
            final y = b.property.createdAt?.millisecondsSinceEpoch ?? 0;
            return y.compareTo(x);
          });
      return out;
    }),
  );

  @override
  Future<void> setPropertyListed(String propertyId, {required bool listed}) =>
      _guard(() async {
        final batch = _db.batch();
        batch.update(_col(FirestoreCollections.properties).doc(propertyId), {
          'isAvailable': listed,
          'adminUnlisted': !listed,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        batch.set(
          _col(FirestoreCollections.adminLogs).doc(),
          _log(
            listed ? 'relist_property' : 'unlist_property',
            propertyId,
            'property',
            null,
          ),
        );
        await batch.commit();
      });

  // ---------------- analytics ----------------

  Future<int> _count(Query<Map<String, dynamic>> q) async =>
      (await q.count().get()).count ?? 0;

  @override
  Future<AdminStats> fetchStats() => _guard(() async {
    final users = _col(FirestoreCollections.users);
    final props = _col(FirestoreCollections.properties);
    final inquiries = _col(FirestoreCollections.inquiries);

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final days = [
      for (var i = 6; i >= 0; i--) startOfToday.subtract(Duration(days: i)),
    ];

    final results = await Future.wait([
      _count(users.where('role', isEqualTo: 'tenant')),
      _count(users.where('role', isEqualTo: 'owner')),
      _count(props),
      _count(props.where('isAvailable', isEqualTo: true)),
      _count(
        _col(
          FirestoreCollections.ownerProfiles,
        ).where('verificationStatus', isEqualTo: 'pending'),
      ),
      _count(inquiries),
      _count(inquiries.where('status', isEqualTo: 'booked')),
      for (final d in days)
        _count(
          users
              .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(d))
              .where(
                'createdAt',
                isLessThan: Timestamp.fromDate(
                  DateTime(d.year, d.month, d.day + 1),
                ),
              ),
        ),
    ]);

    return AdminStats(
      tenants: results[0],
      owners: results[1],
      properties: results[2],
      activeProperties: results[3],
      pendingVerifications: results[4],
      inquiries: results[5],
      bookings: results[6],
      signupsLast7Days: [
        for (var i = 0; i < days.length; i++)
          DailyCount(days[i], results[7 + i]),
      ],
    );
  });

  @override
  Stream<List<AdminLogDoc>> watchRecentLogs({int limit = 5}) => _mapErrors(
    _col(FirestoreCollections.adminLogs)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(AdminLogDoc.fromSnapshot).toList()),
  );
}
