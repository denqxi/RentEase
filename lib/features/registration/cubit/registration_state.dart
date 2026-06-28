part of 'registration_cubit.dart';

/// State of the registration flow: the current step plus all collected data.
class RegistrationState extends Equatable {
  const RegistrationState({
    this.step = RegistrationStep.role,
    this.data = const RegistrationData(),
  });

  /// Which step of the flow is currently visible.
  final RegistrationStep step;

  /// All information gathered so far.
  final RegistrationData data;

  /// The role step requires a selection before "Continue" is enabled.
  bool get canContinueFromRole => data.role != null;

  /// Total number of progress-tracked form steps for the selected role.
  int get formStepCount => 1;

  RegistrationState copyWith({RegistrationStep? step, RegistrationData? data}) {
    return RegistrationState(
      step: step ?? this.step,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => <Object?>[step, data];
}
