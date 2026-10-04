part of 'invite_cubit.dart';

class InviteState extends Equatable {
  const InviteState({
    this.isLoading = true,
    this.isSending = false,
    this.options = const [],
    this.errorMessage,
    this.sentTitle,
  });

  final bool isLoading;
  final bool isSending;

  /// Properties this tenant can be invited to right now.
  final List<InviteOption> options;
  final String? errorMessage;

  /// Title of the property an invitation was just sent for (one-off effect).
  final String? sentTitle;

  /// CLAUDE.md rule 2: the Invite button is absent — never disabled — unless
  /// this is true.
  bool get canInvite => !isLoading && options.isNotEmpty;

  InviteState copyWith({
    bool? isLoading,
    bool? isSending,
    List<InviteOption>? options,
    String? errorMessage,
    bool clearError = false,
    String? sentTitle,
    bool clearSent = false,
  }) {
    return InviteState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      options: options ?? this.options,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sentTitle: clearSent ? null : (sentTitle ?? this.sentTitle),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSending,
    options,
    errorMessage,
    sentTitle,
  ];
}
