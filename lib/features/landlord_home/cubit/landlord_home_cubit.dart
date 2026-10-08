import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore/models/models.dart';
import '../../../core/utils/date_utils.dart';
import '../../owner/domain/repositories/find_tenants_repository.dart';
import '../../owner/domain/repositories/owner_property_repository.dart';
import '../../owner/model/compatible_tenant.dart';

part 'landlord_home_state.dart';

/// Owner home: the signed-in owner's account, real listings and compatible
/// tenants. Everything is read-only here — the owner has no write access to
/// `matches`, and compatible tenants (bScore = 1) are listed unranked
/// (CLAUDE.md: no owner-side TOPSIS). Tenants load for every owner regardless
/// of verification status (October 2026: verification is a badge only).
class LandlordHomeCubit extends Cubit<LandlordHomeState> {
  /// A null [ownerId] (signed out / offline preview) yields an empty,
  /// non-loading state and never touches the repositories.
  LandlordHomeCubit({
    String? ownerId,
    OwnerPropertyRepository? propertyRepository,
    FindTenantsRepository? tenantsRepository,
  }) : _ownerId = ownerId,
       _properties = propertyRepository,
       _tenants = tenantsRepository,
       super(
         LandlordHomeState(isLoading: ownerId != null && propertyRepository != null),
       ) {
    if (ownerId != null && propertyRepository != null) {
      _start(ownerId, propertyRepository);
    }
  }

  final String? _ownerId;
  final OwnerPropertyRepository? _properties;
  final FindTenantsRepository? _tenants;
  StreamSubscription<List<PropertyDoc>>? _propertiesSub;
  StreamSubscription<String>? _statusSub;
  bool _gotProperties = false;
  bool _gotStatus = false;
  int _tenantsRequest = 0;
  String? _tenantsKey;

  void _start(String ownerId, OwnerPropertyRepository repo) {
    repo
        .fetchUser(ownerId)
        .then((user) {
          if (isClosed || user == null) return;
          final full = [
            user.firstName,
            user.lastName,
          ].where((s) => s.trim().isNotEmpty).join(' ');
          emit(
            state.copyWith(
              fullName: full,
              firstName: firstNameOf(
                user.firstName.trim().isNotEmpty ? user.firstName : full,
              ),
              photoUrl: user.profilePhoto,
            ),
          );
        })
        .catchError((Object _) {
          // The greeting falls back to its neutral form; not worth a banner.
        });
    _propertiesSub = repo.watchOwnerProperties(ownerId).listen((properties) {
      _gotProperties = true;
      emit(
        state.copyWith(
          properties: properties,
          isLoading: !_gotStatus,
          clearError: true,
        ),
      );
      _refreshTenants();
    }, onError: _onError);
    _statusSub = repo.watchVerificationStatus(ownerId).listen((status) {
      _gotStatus = true;
      emit(
        state.copyWith(
          verificationStatus: status,
          isLoading: !_gotProperties,
          clearError: true,
        ),
      );
      _refreshTenants();
    }, onError: _onError);
  }

  /// Reloads the compatible-tenant list only when the set of available
  /// listings changes (not on every unrelated edit).
  Future<void> _refreshTenants({bool force = false}) async {
    final repo = _tenants;
    final ownerId = _ownerId;
    if (repo == null || ownerId == null || !_gotProperties) return;
    final ids = [
      for (final p in state.properties)
        if (p.isAvailable) p.propertyId,
    ]..sort();
    final key = ids.join(',');
    if (!force && key == _tenantsKey) return;
    _tenantsKey = key;
    final request = ++_tenantsRequest;
    if (ids.isEmpty) {
      emit(
        state.copyWith(
          tenants: const [],
          tenantsLoading: false,
          clearTenantsError: true,
        ),
      );
      return;
    }
    emit(state.copyWith(tenantsLoading: true, clearTenantsError: true));
    try {
      final lists = await Future.wait(
        ids.map(
          (id) => repo.fetchCompatibleTenants(ownerId: ownerId, propertyId: id),
        ),
      );
      if (isClosed || request != _tenantsRequest) return;
      final byTenant = <String, CompatibleTenant>{};
      for (final t in lists.expand((l) => l)) {
        byTenant.putIfAbsent(t.tenantId, () => t);
      }
      // Unranked: alphabetical, so the order carries no fit signal.
      final sorted = byTenant.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      emit(state.copyWith(tenants: sorted, tenantsLoading: false));
    } catch (_) {
      if (isClosed || request != _tenantsRequest) return;
      _tenantsKey = null;
      emit(
        state.copyWith(
          tenantsLoading: false,
          tenantsError: 'Could not load compatible tenants. Please try again.',
        ),
      );
    }
  }

  /// Retry / pull-to-refresh for the tenant list.
  Future<void> reloadTenants() => _refreshTenants(force: true);

  /// Pull-to-refresh for the entire home screen: re-reads user account and tenants.
  Future<void> refresh() async {
    final id = _ownerId;
    final repo = _properties;
    if (id != null && repo != null) {
      try {
        final user = await repo.fetchUser(id);
        if (!isClosed && user != null) {
          final full = [
            user.firstName,
            user.lastName,
          ].where((s) => s.trim().isNotEmpty).join(' ');
          emit(
            state.copyWith(
              fullName: full,
              firstName: firstNameOf(
                user.firstName.trim().isNotEmpty ? user.firstName : full,
              ),
              photoUrl: user.profilePhoto,
            ),
          );
        }
      } catch (_) {
        // Ignored; tenant reload still proceeds.
      }
    }
    await reloadTenants();
  }

  void _onError(Object e) {
    if (isClosed) return;
    emit(
      state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load your account. Please try again.',
      ),
    );
  }

  /// Retry after a load failure: resubscribes from scratch.
  void retry() {
    final id = _ownerId;
    final repo = _properties;
    if (id == null || repo == null) return;
    _propertiesSub?.cancel();
    _statusSub?.cancel();
    _gotProperties = false;
    _gotStatus = false;
    _tenantsKey = null;
    emit(state.copyWith(isLoading: true, clearError: true));
    _start(id, repo);
  }

  /// Updates the live search query.
  void updateSearch(String query) => emit(state.copyWith(searchQuery: query));

  @override
  Future<void> close() {
    _propertiesSub?.cancel();
    _statusSub?.cancel();
    return super.close();
  }
}
