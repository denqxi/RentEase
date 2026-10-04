import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/activity/domain/repositories/notification_repository.dart';
import 'package:rentease/features/inquiry/domain/repositories/inquiry_repository.dart';
import 'package:rentease/features/inquiry/domain/services/inquiry_service.dart';

const _tenant = 'tenantA';
const _owner = 'ownerA';
const _property = 'prop1';
const _matchId = '${_tenant}_$_property';

MatchDoc _match({num bScore = 1, String tenantId = _tenant}) => MatchDoc(
  matchId: _matchId,
  tenantId: tenantId,
  ownerId: _owner,
  propertyId: _property,
  pScore: bScore,
  tScore: bScore,
  bScore: bScore,
  tenantCi: 0.82,
);

InquiryDoc _inquiry({
  num stage = 1,
  String status = 'pending',
  String ownerDecision = 'pending',
}) => InquiryDoc(
  inquiryId: _matchId,
  matchId: _matchId,
  tenantId: _tenant,
  ownerId: _owner,
  propertyId: _property,
  tenantCiSnapshot: 0.82,
  stage: stage,
  initiatedBy: 'tenant',
  status: status,
  ownerDecision: ownerDecision,
  autoInfoSent: true,
);

PropertyDoc _propertyDoc({bool isAvailable = true}) => PropertyDoc(
  propertyId: _property,
  ownerId: _owner,
  title: 'Sunshine Boarding House',
  address: 'Matina',
  location: const GeoPoint(7.07, 125.6),
  geoHash: '',
  photos: const [],
  monthlyRent: 4000,
  depositAmount: 4000,
  advanceMonths: 1,
  isAvailable: isAvailable,
  vacancyStatus: isAvailable ? 'available' : 'booked',
  isVerified: true,
  allowedGender: 'Mixed / Any',
  smokingAllowed: false,
  petsAllowed: false,
  maxOccupants: 2,
  hasWifi: true,
  amenityList: const ['WiFi'],
);

/// In-memory stand-in for Firestore — records every write.
class _FakeRepository implements InquiryRepository {
  MatchDoc? match;
  PropertyDoc? property = _propertyDoc();
  InquiryDoc? existing;
  List<InquiryDoc> openForProperty = [];
  bool alreadyRated = false;
  Map<String, Object>? booking;

  final created = <InquiryDoc>[];
  final updates = <Map<String, dynamic>>[];
  final messages = <MessageDoc>[];
  final ratings = <RatingDoc>[];

  @override
  Future<InquiryDoc?> findTenantInquiryForMatch({
    required String tenantId,
    required String matchId,
  }) async => existing;

  @override
  Future<MatchDoc?> fetchMatch(String matchId) async => match;

  @override
  Future<PropertyDoc?> fetchProperty(String propertyId) async => property;

  @override
  Future<List<InquiryDoc>> fetchOpenInquiriesForProperty({
    required String ownerId,
    required String propertyId,
  }) async => openForProperty;

  @override
  Future<void> commitBooking({
    required String inquiryId,
    required String propertyId,
    required bool fillsLastVacancy,
    required List<String> otherInquiryIds,
  }) async => booking = {
    'inquiryId': inquiryId,
    'propertyId': propertyId,
    'fillsLastVacancy': fillsLastVacancy,
    'otherInquiryIds': otherInquiryIds,
  };

  @override
  Future<void> createInquiry(InquiryDoc inquiry) async => created.add(inquiry);

  @override
  Future<void> updateInquiry(String inquiryId, Map<String, dynamic> fields) async =>
      updates.add(fields);

  @override
  Future<void> addMessage(String inquiryId, MessageDoc message) async =>
      messages.add(message);

  @override
  Future<void> createRating(RatingDoc rating) async => ratings.add(rating);

  @override
  Future<bool> hasRated({required String inquiryId, required String raterId}) async =>
      alreadyRated;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeNotifications implements NotificationRepository {
  _FakeNotifications({this.fail = false});
  final bool fail;
  final created = <NotificationDoc>[];
  final upserted = <NotificationDoc>[];

  @override
  Future<void> create(NotificationDoc notification) async {
    if (fail) throw Exception('permission-denied');
    created.add(notification);
  }

  @override
  Future<void> upsert(NotificationDoc notification) async {
    if (fail) throw Exception('permission-denied');
    upserted.add(notification);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _FakeRepository repo;
  late InquiryService service;

  setUp(() {
    repo = _FakeRepository();
    service = InquiryService(repository: repo);
  });

  group('sendInquiry (Phase 1)', () {
    test('creates a stage-1 pending inquiry keyed by the match ID', () async {
      repo.match = _match();

      final id = await service.sendInquiry(tenantId: _tenant, matchId: _matchId);

      expect(id, _matchId);
      final created = repo.created.single;
      expect(created.inquiryId, _matchId);
      expect(created.ownerId, _owner);
      expect(created.propertyId, _property);
      expect(created.stage, 1);
      expect(created.ownerDecision, 'pending');
      expect(created.status, 'pending');
      expect(created.tenantCiSnapshot, 0.82);
    });

    test('reuses an existing open inquiry instead of duplicating it', () async {
      repo.existing = _inquiry();

      final id = await service.sendInquiry(tenantId: _tenant, matchId: _matchId);

      expect(id, _matchId);
      expect(repo.created, isEmpty);
    });

    test('refuses to reopen an inquiry the owner declined', () {
      repo.existing = _inquiry(ownerDecision: 'declined', status: 'declined');
      expect(
        service.sendInquiry(tenantId: _tenant, matchId: _matchId),
        throwsA(isA<InquiryException>()),
      );
    });

    test('refuses an incompatible (bScore = 0) match', () {
      repo.match = _match(bScore: 0);
      expect(
        service.sendInquiry(tenantId: _tenant, matchId: _matchId),
        throwsA(isA<InquiryException>()),
      );
    });

    test("refuses another tenant's match", () {
      repo.match = _match(tenantId: 'someoneElse');
      expect(
        service.sendInquiry(tenantId: _tenant, matchId: _matchId),
        throwsA(isA<InquiryException>()),
      );
    });

    test('refuses a fully booked property even with a live match row', () {
      repo.match = _match();
      repo.property = _propertyDoc(isAvailable: false);
      expect(
        service.sendInquiry(tenantId: _tenant, matchId: _matchId),
        throwsA(isA<InquiryException>()),
      );
      expect(repo.created, isEmpty);
    });

    test('refuses to reopen an inquiry closed by a full booking', () {
      repo.existing = _inquiry(status: 'closed');
      expect(
        service.sendInquiry(tenantId: _tenant, matchId: _matchId),
        throwsA(isA<InquiryException>()),
      );
    });

    test('refuses when there is no match at all', () {
      expect(
        service.sendInquiry(tenantId: _tenant, matchId: _matchId),
        throwsA(isA<InquiryException>()),
      );
    });
  });

  group('accept / decline', () {
    test('accept unlocks Phase 2', () async {
      await service.accept(inquiry: _inquiry(), ownerId: _owner);
      expect(repo.updates.single, {
        'stage': 2,
        'ownerDecision': 'accepted',
        'status': 'active',
      });
    });

    test('only the owner can accept', () {
      expect(
        service.accept(inquiry: _inquiry(), ownerId: _tenant),
        throwsA(isA<InquiryException>()),
      );
    });

    test('cannot accept an inquiry closed by a full booking', () {
      expect(
        service.accept(inquiry: _inquiry(status: 'closed'), ownerId: _owner),
        throwsA(isA<InquiryException>()),
      );
    });

    test('cannot accept an inquiry that was already answered', () {
      expect(
        service.accept(
          inquiry: _inquiry(stage: 2, ownerDecision: 'accepted', status: 'active'),
          ownerId: _owner,
        ),
        throwsA(isA<InquiryException>()),
      );
    });

    test('decline stores a trimmed reason, and omits a blank one', () async {
      await service.decline(inquiry: _inquiry(), ownerId: _owner, reason: '  Full  ');
      await service.decline(inquiry: _inquiry(), ownerId: _owner, reason: '   ');
      expect(repo.updates[0], {
        'ownerDecision': 'declined',
        'status': 'declined',
        'declineReason': 'Full',
      });
      expect(repo.updates[1].containsKey('declineReason'), isFalse);
    });
  });

  group('sendMessage (Phase 2)', () {
    final chat = _inquiry(stage: 2, ownerDecision: 'accepted', status: 'active');

    test('is locked during Phase 1', () {
      expect(
        service.sendMessage(inquiry: _inquiry(), senderId: _tenant, content: 'hi'),
        throwsA(isA<InquiryException>()),
      );
    });

    test('records the sender role and trims the content', () async {
      await service.sendMessage(inquiry: chat, senderId: _tenant, content: ' hi ');
      await service.sendMessage(inquiry: chat, senderId: _owner, content: 'hello');
      expect(repo.messages[0].senderRole, 'tenant');
      expect(repo.messages[0].content, 'hi');
      expect(repo.messages[0].isAutoGenerated, isFalse);
      expect(repo.messages[1].senderRole, 'owner');
    });

    test('ignores blank messages', () async {
      await service.sendMessage(inquiry: chat, senderId: _tenant, content: '   ');
      expect(repo.messages, isEmpty);
    });

    test('rejects a sender who is not part of the inquiry', () {
      expect(
        service.sendMessage(inquiry: chat, senderId: 'stranger', content: 'hi'),
        throwsA(isA<InquiryException>()),
      );
    });

    test('is closed once booked', () {
      expect(
        service.sendMessage(
          inquiry: _inquiry(stage: 2, ownerDecision: 'accepted', status: 'booked'),
          senderId: _tenant,
          content: 'hi',
        ),
        throwsA(isA<InquiryException>()),
      );
    });
  });

  group('markBooked + submitRating', () {
    final booked = _inquiry(stage: 2, ownerDecision: 'accepted', status: 'booked');

    final active = _inquiry(stage: 2, ownerDecision: 'accepted', status: 'active');

    test('booking keeps the listing up by default', () async {
      await service.markBooked(inquiry: active, ownerId: _owner);
      expect(repo.booking, {
        'inquiryId': _matchId,
        'propertyId': _property,
        'fillsLastVacancy': false,
        'otherInquiryIds': <String>[],
      });
    });

    test('filling the last vacancy closes every other open inquiry', () async {
      repo.openForProperty = [
        active, // the one being booked — must not close itself
        InquiryDoc.fromMap('tenantB_prop1', {
          'tenantId': 'tenantB',
          'ownerId': _owner,
          'propertyId': _property,
          'status': 'pending',
        }),
      ];
      await service.markBooked(
        inquiry: active,
        ownerId: _owner,
        fillsLastVacancy: true,
      );
      expect(repo.booking!['fillsLastVacancy'], isTrue);
      expect(repo.booking!['otherInquiryIds'], ['tenantB_prop1']);
    });

    test('cannot book an inquiry still in Phase 1', () {
      expect(
        service.markBooked(inquiry: _inquiry(), ownerId: _owner),
        throwsA(isA<InquiryException>()),
      );
    });

    test('tenant rates the owner; owner rates the tenant', () async {
      await service.submitRating(inquiry: booked, raterId: _tenant, stars: 5);
      await service.submitRating(
        inquiry: booked,
        raterId: _owner,
        stars: 4,
        review: ' Great tenant ',
      );
      expect(repo.ratings[0].ratedId, _owner);
      expect(repo.ratings[0].raterRole, 'tenant');
      expect(repo.ratings[1].ratedId, _tenant);
      expect(repo.ratings[1].raterRole, 'owner');
      expect(repo.ratings[1].review, 'Great tenant');
    });

    test('rating requires a confirmed booking', () {
      expect(
        service.submitRating(
          inquiry: _inquiry(stage: 2, ownerDecision: 'accepted', status: 'active'),
          raterId: _tenant,
          stars: 5,
        ),
        throwsA(isA<InquiryException>()),
      );
    });

    test('rejects out-of-range stars and duplicate ratings', () async {
      expect(
        service.submitRating(inquiry: booked, raterId: _tenant, stars: 0),
        throwsA(isA<InquiryException>()),
      );
      repo.alreadyRated = true;
      expect(
        service.submitRating(inquiry: booked, raterId: _tenant, stars: 5),
        throwsA(isA<InquiryException>()),
      );
    });
  });

  group('notifications', () {
    test('inquiry, accept, decline and message notify the right party',
        () async {
      final notes = _FakeNotifications();
      final svc = InquiryService(repository: repo, notifications: notes);

      repo.match = _match();
      await svc.sendInquiry(tenantId: _tenant, matchId: _matchId);
      await svc.accept(inquiry: _inquiry(), ownerId: _owner);
      await svc.decline(inquiry: _inquiry(), ownerId: _owner);
      final active = _inquiry(
        stage: 2,
        ownerDecision: 'accepted',
        status: 'active',
      );
      await svc.sendMessage(inquiry: active, senderId: _tenant, content: 'Hi');
      await svc.sendMessage(inquiry: active, senderId: _owner, content: 'Hello');

      expect(notes.created.map((n) => (n.type, n.recipientId)).toList(), [
        ('inquiry', _owner),
        ('inquiry_accepted', _tenant),
        ('inquiry_declined', _tenant),
      ]);
      expect(notes.upserted.map((n) => (n.type, n.recipientId)).toList(), [
        ('message', _owner),
        ('message', _tenant),
      ]);
    });

    test('message alert has no chat text and reuses one doc id per recipient',
        () async {
      final notes = _FakeNotifications();
      final svc = InquiryService(repository: repo, notifications: notes);
      final active = _inquiry(
        stage: 2,
        ownerDecision: 'accepted',
        status: 'active',
      );
      await svc.sendMessage(
        inquiry: active,
        senderId: _tenant,
        content: 'secret deposit details',
      );
      await svc.sendMessage(
        inquiry: active,
        senderId: _tenant,
        content: 'another secret',
      );

      expect(notes.created, isEmpty);
      expect(notes.upserted, hasLength(2));
      expect(notes.upserted[0].notifId, 'msg_${active.inquiryId}_$_owner');
      expect(notes.upserted[1].notifId, notes.upserted[0].notifId);
      for (final n in notes.upserted) {
        expect(n.body, isNot(contains('secret')));
        expect(n.isRead, isFalse);
      }
    });

    test('a failing message alert never breaks sendMessage', () async {
      final svc = InquiryService(
        repository: repo,
        notifications: _FakeNotifications(fail: true),
      );
      final active = _inquiry(
        stage: 2,
        ownerDecision: 'accepted',
        status: 'active',
      );
      await svc.sendMessage(inquiry: active, senderId: _tenant, content: 'Hi');
    });

    test('a failing notification write never breaks the action', () async {
      final svc = InquiryService(
        repository: repo,
        notifications: _FakeNotifications(fail: true),
      );
      repo.match = _match();

      final id = await svc.sendInquiry(tenantId: _tenant, matchId: _matchId);
      await svc.accept(inquiry: _inquiry(), ownerId: _owner);

      expect(id, _matchId);
      expect(repo.created, hasLength(1));
      expect(repo.updates, hasLength(1));
    });
  });
}
