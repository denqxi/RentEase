part of 'listing_detail_cubit.dart';

/// State for [ListingDetailCubit].
class ListingDetailState extends Equatable {
  const ListingDetailState({required this.detail});

  final ListingDetail detail;

  ListingDetailState copyWith({ListingDetail? detail}) =>
      ListingDetailState(detail: detail ?? this.detail);

  @override
  List<Object?> get props => <Object?>[detail];
}
