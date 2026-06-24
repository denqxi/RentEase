part of 'tenant_detail_cubit.dart';

/// State for [TenantDetailCubit].
class TenantDetailState extends Equatable {
  const TenantDetailState({required this.detail});

  final TenantDetail detail;

  TenantDetailState copyWith({TenantDetail? detail}) =>
      TenantDetailState(detail: detail ?? this.detail);

  @override
  List<Object?> get props => <Object?>[detail];
}
