import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/activity/domain/repositories/notification_repository.dart';
import 'package:rentease/features/inquiry/domain/repositories/inquiry_repository.dart';

const kOwner = 'ownerA';
const kTenant = 'tenantA';
const kProp1 = 'prop1';
const kProp2 = 'prop2';

String matchIdFor(String propertyId) => '${kTenant}_$propertyId';

MatchDoc matchFor(
  String propertyId, {
  num bScore = 1,
  String ownerId = kOwner,
  String tenantId = kTenant,
}) => MatchDoc(
  matchId: matchIdFor(propertyId),
  tenantId: tenantId,
  ownerId: ownerId,
  propertyId: propertyId,
  pScore: bScore,
  tScore: bScore,
  bScore: bScore,
  tenantCi: 0.7,
);

PropertyDoc propertyFor(
  String propertyId, {
  bool isAvailable = true,
  String ownerId = kOwner,
}) => PropertyDoc(
  propertyId: propertyId,
  ownerId: ownerId,
  title: 'House $propertyId',
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

InquiryDoc threadFor(
  String propertyId, {
  String initiatedBy = 'owner',
  num stage = 1,
  String status = 'pending',
  String decision = 'pending',
}) => InquiryDoc(
  inquiryId: matchIdFor(propertyId),
  matchId: matchIdFor(propertyId),
  tenantId: kTenant,
  ownerId: kOwner,
  propertyId: propertyId,
  tenantCiSnapshot: 0.7,
  stage: stage,
  initiatedBy: initiatedBy,
  status: status,
  ownerDecision: decision,
  autoInfoSent: true,
);

/// In-memory stand-in for Firestore used by the invitation tests.
class FakeInviteRepository implements InquiryRepository {
  String ownerStatus = 'verified';
  List<MatchDoc> matches = [];
  List<InquiryDoc> threads = [];
  Map<String, PropertyDoc> properties = {};

  final created = <InquiryDoc>[];
  final updates = <Map<String, dynamic>>[];

  @override
  Future<OwnerProfileDoc?> fetchOwnerProfile(String uid) async =>
      OwnerProfileDoc(userId: uid, verificationStatus: ownerStatus);

  @override
  Future<List<MatchDoc>> fetchCompatibleMatchesWithTenant({
    required String ownerId,
    required String tenantId,
  }) async => matches;

  @override
  Future<List<InquiryDoc>> fetchInquiriesBetween({
    required String ownerId,
    required String tenantId,
  }) async => threads;

  @override
  Future<MatchDoc?> fetchMatch(String matchId) async {
    for (final m in matches) {
      if (m.matchId == matchId) return m;
    }
    return null;
  }

  @override
  Future<PropertyDoc?> fetchProperty(String propertyId) async =>
      properties[propertyId];

  @override
  Future<void> createInquiry(InquiryDoc inquiry) async => created.add(inquiry);

  @override
  Future<void> updateInquiry(
    String inquiryId,
    Map<String, dynamic> fields,
  ) async => updates.add(fields);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakeNotifications implements NotificationRepository {
  FakeNotifications({this.fail = false});
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
