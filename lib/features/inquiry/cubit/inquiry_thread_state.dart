part of 'inquiry_thread_cubit.dart';

class InquiryThreadState extends Equatable {
  const InquiryThreadState({
    this.isLoading = true,
    this.isBusy = false,
    this.errorMessage,
    this.inquiry,
    this.messages = const [],
    this.property,
    this.tenant,
    this.tenantProfile,
    this.owner,
    this.ownerVerified = false,
  });

  final bool isLoading;

  /// An accept/decline/send/book/rate call is in flight.
  final bool isBusy;
  final String? errorMessage;

  final InquiryDoc? inquiry;
  final List<MessageDoc> messages;

  final PropertyDoc? property;
  final UserDoc? tenant;
  final TenantProfileDoc? tenantProfile;
  final UserDoc? owner;
  final bool ownerVerified;

  InquiryThreadState copyWith({
    bool? isLoading,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
    InquiryDoc? inquiry,
    List<MessageDoc>? messages,
    PropertyDoc? property,
    UserDoc? tenant,
    TenantProfileDoc? tenantProfile,
    UserDoc? owner,
    bool? ownerVerified,
  }) {
    return InquiryThreadState(
      isLoading: isLoading ?? this.isLoading,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      inquiry: inquiry ?? this.inquiry,
      messages: messages ?? this.messages,
      property: property ?? this.property,
      tenant: tenant ?? this.tenant,
      tenantProfile: tenantProfile ?? this.tenantProfile,
      owner: owner ?? this.owner,
      ownerVerified: ownerVerified ?? this.ownerVerified,
    );
  }

  // The Firestore models have no value equality, so each new snapshot is a
  // new object and re-emits — which is exactly when the thread should rebuild.
  @override
  List<Object?> get props => [
    isLoading,
    isBusy,
    errorMessage,
    inquiry,
    messages,
    property,
    tenant,
    tenantProfile,
    owner,
    ownerVerified,
  ];
}
