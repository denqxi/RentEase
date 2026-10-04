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
    this.verificationStatus,
    this.errorMessage,
  });

  final bool isLoading;
  final List<PropertyDoc> properties;
  final int openInquiries;

  /// 'none' | 'pending' | 'verified' | 'rejected'; null until first read.
  final String? verificationStatus;
  final String? errorMessage;

  /// Show the "listing is live, badge pending" banner: owner known to be
  /// unverified.
  bool get showPendingBanner =>
      verificationStatus != null && verificationStatus != 'verified';

  int get availableCount => properties.where((p) => p.isAvailable).length;

  OwnerPropertiesState copyWith({
    bool? isLoading,
    List<PropertyDoc>? properties,
    int? openInquiries,
    String? verificationStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OwnerPropertiesState(
      isLoading: isLoading ?? this.isLoading,
      properties: properties ?? this.properties,
      openInquiries: openInquiries ?? this.openInquiries,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    properties,
    openInquiries,
    verificationStatus,
    errorMessage,
  ];
}

/// "My properties": the owner's listings, live, plus availability changes
/// and edits. Marking a listing unavailable drops it from every tenant's
/// matches on their next filtering pass; marking it available again
/// (relisting) brings it back the same way — no Cloud Functions involved.
class OwnerPropertiesCubit extends Cubit<OwnerPropertiesState> {
  OwnerPropertiesCubit({
    required this.ownerId,
    required this._repository,
  }) : super(const OwnerPropertiesState()) {
    _propertiesSub = _repository
        .watchOwnerProperties(ownerId)
        .listen(
          (properties) {
            if (!isClosed) {
              emit(state.copyWith(isLoading: false, properties: properties));
              _publishIfVerified();
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
    _statusSub = _repository
        .watchVerificationStatus(ownerId)
        .listen(
          (status) {
            if (!isClosed) {
              emit(state.copyWith(verificationStatus: status));
              _publishIfVerified();
            }
          },
          onError: _onError,
        );
  }

  final String ownerId;
  final OwnerPropertyRepository _repository;
  StreamSubscription<List<PropertyDoc>>? _propertiesSub;
  StreamSubscription<int>? _inquiriesSub;
  StreamSubscription<String>? _statusSub;
  bool _publishing = false;

  /// Listings are live from creation (Oct 2026); `properties.isVerified` is
  /// only the badge flag. Once the owner is verified, sync it onto listings
  /// created earlier. Idempotent and single-flight.
  Future<void> _publishIfVerified() async {
    if (_publishing || state.verificationStatus != 'verified') return;
    final stale = [
      for (final p in state.properties)
        if (!p.isVerified) p.propertyId,
    ];
    if (stale.isEmpty) return;
    _publishing = true;
    try {
      await _repository.publishListings(stale);
    } catch (e) {
      _onError(e);
    } finally {
      _publishing = false;
    }
  }

  /// 'available' | 'pending' | 'booked'. Only 'available' is shown to
  /// tenants (`isAvailable` mirrors it for the matching engine's query).
  Future<void> setVacancy(String propertyId, String status) {
    // An admin-unlisted property can't be relisted by the owner (rules deny
    // it); say so instead of attempting a write that fails.
    final unlisted = state.properties.any(
      (p) => p.propertyId == propertyId && p.adminUnlisted,
    );
    if (unlisted) {
      _onError(Exception(adminUnlistedMessage));
      return Future.value();
    }
    return _update(propertyId, {
      'vacancyStatus': status,
      'isAvailable': status == 'available',
    });
  }

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
    _statusSub?.cancel();
    return super.close();
  }
}
