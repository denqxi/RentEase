import 'package:equatable/equatable.dart';

import '../../../../core/firestore/models/models.dart';

/// An owner's verification record joined with the owner's name.
class VerificationItem extends Equatable {
  const VerificationItem({
    required this.profile,
    required this.ownerName,
    this.ownerEmail = '',
  });

  final OwnerProfileDoc profile;
  final String ownerName;
  final String ownerEmail;

  String get ownerId => profile.userId;
  String get status => profile.verificationStatus;

  @override
  List<Object?> get props => [
    profile.userId,
    profile.verificationStatus,
    profile.submittedAt,
    ownerName,
  ];
}

/// Document references from `ownerProfiles/{uid}/private/documents`.
/// Cloudinary delivery is private/authenticated, so URLs may not open
/// in-app; the admin works from the public IDs in the Media Library.
class VerificationDocuments extends Equatable {
  const VerificationDocuments({
    this.urls = const [],
    this.publicIds = const [],
  });

  final List<String> urls;
  final List<String> publicIds;

  bool get isEmpty => urls.isEmpty && publicIds.isEmpty;

  @override
  List<Object?> get props => [urls, publicIds];
}

class AdminPropertyItem extends Equatable {
  const AdminPropertyItem({
    required this.property,
    required this.ownerName,
    this.adminUnlisted = false,
  });

  final PropertyDoc property;
  final String ownerName;

  /// Unlisted by an admin (owner cannot relist).
  final bool adminUnlisted;

  @override
  List<Object?> get props => [
    property.propertyId,
    property.isAvailable,
    property.isVerified,
    property.monthlyRent,
    ownerName,
    adminUnlisted,
  ];
}

/// Dashboard numbers from Firestore count() aggregates.
class AdminStats extends Equatable {
  const AdminStats({
    this.tenants = 0,
    this.owners = 0,
    this.properties = 0,
    this.activeProperties = 0,
    this.pendingVerifications = 0,
    this.inquiries = 0,
    this.bookings = 0,
    this.signupsLast7Days = const [],
  });

  final int tenants;
  final int owners;
  final int properties;
  final int activeProperties;
  final int pendingVerifications;
  final int inquiries;
  final int bookings;

  /// Oldest first, one entry per day ending today.
  final List<DailyCount> signupsLast7Days;

  int get totalUsers => tenants + owners;

  @override
  List<Object?> get props => [
    tenants,
    owners,
    properties,
    activeProperties,
    pendingVerifications,
    inquiries,
    bookings,
    signupsLast7Days,
  ];
}

class DailyCount extends Equatable {
  const DailyCount(this.day, this.count);

  final DateTime day;
  final int count;

  @override
  List<Object?> get props => [day, count];
}

/// Friendly, UI-safe failure; never carries raw Firebase text.
class AdminException implements Exception {
  const AdminException(this.message);

  final String message;

  @override
  String toString() => message;
}
