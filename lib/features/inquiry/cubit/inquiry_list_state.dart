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

  @override
  List<Object?> get props => [isLoading, items, errorMessage];
}
