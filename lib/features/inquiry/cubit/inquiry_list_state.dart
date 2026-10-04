part of 'inquiry_list_cubit.dart';

class InquiryListState extends Equatable {
  const InquiryListState({
    this.isLoading = true,
    this.items = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<InquirySummary> items;
  final String? errorMessage;

  /// Awaiting the owner, or chat open.
  List<InquirySummary> get active =>
      items.where((s) => !InquiryService.isResolved(s.inquiry)).toList();

  /// Booked, declined, or closed.
  List<InquirySummary> get resolved =>
      items.where((s) => InquiryService.isResolved(s.inquiry)).toList();

  // Owner inbox views: tenant-initiated inquiries vs the owner's own
  // invitations (kept together in "Sent" whatever their status).

  /// Tenant-initiated inquiries still awaiting the owner, or in chat.
  List<InquirySummary> get incoming => items
      .where(
        (s) =>
            !InquiryService.isInvite(s.inquiry) &&
            !InquiryService.isResolved(s.inquiry),
      )
      .toList();

  /// Every invitation this owner sent, with its status.
  List<InquirySummary> get sentInvitations =>
      items.where((s) => InquiryService.isInvite(s.inquiry)).toList();

  /// Resolved tenant-initiated inquiries.
  List<InquirySummary> get history => items
      .where(
        (s) =>
            !InquiryService.isInvite(s.inquiry) &&
            InquiryService.isResolved(s.inquiry),
      )
      .toList();

  @override
  List<Object?> get props => [isLoading, items, errorMessage];
}
