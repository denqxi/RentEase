import 'package:equatable/equatable.dart';

import '../../../core/firestore/models/models.dart';

/// One row in an inquiry inbox — the inquiry plus the display names the
/// list needs (the property, and whoever is on the other side).
class InquirySummary extends Equatable {
  const InquirySummary({
    required this.inquiry,
    required this.propertyTitle,
    required this.counterpartName,
  });

  final InquiryDoc inquiry;
  final String propertyTitle;

  /// The owner's name on the tenant side, the tenant's on the owner side.
  final String counterpartName;

  String get propertyInitials => initialsOf(propertyTitle);
  String get counterpartInitials => initialsOf(counterpartName);

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
  }

  @override
  List<Object?> get props => [
    inquiry.inquiryId,
    inquiry.stage,
    inquiry.status,
    inquiry.ownerDecision,
    inquiry.updatedAt,
    propertyTitle,
    counterpartName,
  ];
}

/// Short relative date for inbox rows, e.g. "Today", "Yesterday", "Sep 12".
String inquiryDateLabel(DateTime? at) {
  if (at == null) return 'Just now';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[at.month - 1]} ${at.day}';
}

String fullNameOf(UserDoc? user, {required String fallback}) {
  if (user == null) return fallback;
  final name = '${user.firstName} ${user.lastName}'.trim();
  return name.isEmpty ? fallback : name;
}
