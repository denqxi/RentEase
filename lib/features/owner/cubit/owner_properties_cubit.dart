import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore/models/models.dart';
import '../domain/repositories/owner_property_repository.dart';

class OwnerPropertiesState extends Equatable {
  const OwnerPropertiesState({
    this.isLoading = true,
    this.properties = const [],
    this.openInquiries = 0,
    this.errorMessage,
  });

  final bool isLoading;
  final List<PropertyDoc> properties;
  final int openInquiries;
  final String? errorMessage;

  int get availableCount => properties.where((p) => p.isAvailable).length;

  OwnerPropertiesState copyWith({
    bool? isLoading,
    List<PropertyDoc>? properties,
    int? openInquiries,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OwnerPropertiesState(
      isLoading: isLoading ?? this.isLoading,
      properties: properties ?? this.properties,
      openInquiries: openInquiries ?? this.openInquiries,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, properties, openInquiries, errorMessage];
}

/// "My properties": the owner's listings, live, plus availability changes
/// and edits. Marking a listing unavailable drops it from every tenant's
/// matches on their next filtering pass; marking it available again
/// (relisting) brings it back the same way — no Cloud Functions involved.
class OwnerPropertiesCubit extends Cubit<OwnerPropertiesState> {
  OwnerPropertiesCubit({
    required this.ownerId,
    required OwnerPropertyRepository repository,
  }) : _repository = repository,
       super(const OwnerPropertiesState()) {
    _propertiesSub = _repository
        .watchOwnerProperties(ownerId)
        .listen(
          (properties) {
            if (!isClosed) {
              emit(state.copyWith(isLoading: false, properties: properties));
            }
          },
          onError: _onError,
        );
    _inquiriesSub = _repository
        .watchOpenInquiryCount(ownerId)
        .listen(
          (count) {
            if (!isClosed) emit(state.copyWith(openInquiries: count));
          },
          onError: _onError,
        );
  }

  final String ownerId;
  final OwnerPropertyRepository _repository;
  StreamSubscription<List<PropertyDoc>>? _propertiesSub;
  StreamSubscription<int>? _inquiriesSub;

  /// 'available' | 'pending' | 'booked'. Only 'available' is shown to
  /// tenants (`isAvailable` mirrors it for the matching engine's query).
  Future<void> setVacancy(String propertyId, String status) =>
      _update(propertyId, {
        'vacancyStatus': status,
        'isAvailable': status == 'available',
      });

  /// Saves an edit; throws so the edit screen can show the failure.
  Future<void> updateProperty(String propertyId, Map<String, dynamic> fields) =>
      _repository.updateProperty(propertyId, fields);

  Future<void> _update(String propertyId, Map<String, dynamic> fields) async {
    try {
      await _repository.updateProperty(propertyId, fields);
    } catch (e) {
      _onError(e);
    }
  }

  void _onError(Object e) {
    if (isClosed) return;
    emit(
      state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ),
    );
  }

  void clearError() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _propertiesSub?.cancel();
    _inquiriesSub?.cancel();
    return super.close();
  }
}
