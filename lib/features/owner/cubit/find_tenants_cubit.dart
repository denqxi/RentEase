import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/repositories/find_tenants_repository.dart';
import '../model/compatible_tenant.dart';
import '../model/owner_listing.dart';

part 'find_tenants_state.dart';

/// Find Tenants: the owner picks one of their properties and sees the
/// compatible (bScore = 1) tenants for it. Filtering-only — there is no
/// owner-side TOPSIS instance (CLAUDE.md), so the list isn't ranked.
class FindTenantsCubit extends Cubit<FindTenantsState> {
  FindTenantsCubit({
    required this.ownerId,
    required this._repository,
  }) : super(const FindTenantsState()) {
    load();
  }

  final String ownerId;
  final FindTenantsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final listings = await _repository.fetchOwnerListings(ownerId);
      if (isClosed) return;
      if (listings.isEmpty) {
        emit(state.copyWith(isLoading: false, listings: const [], tenants: const []));
        return;
      }
      final selected = listings.any((l) => l.propertyId == state.selectedPropertyId)
          ? state.selectedPropertyId!
          : listings.first.propertyId;
      emit(state.copyWith(listings: listings, selectedPropertyId: selected));
      await _loadTenants(selected);
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, errorMessage: _message(e)));
    }
  }

  Future<void> selectProperty(String propertyId) async {
    if (propertyId == state.selectedPropertyId) return;
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        selectedPropertyId: propertyId,
        tenants: const [],
      ),
    );
    try {
      await _loadTenants(propertyId);
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, errorMessage: _message(e)));
    }
  }

  Future<void> _loadTenants(String propertyId) async {
    final tenants = await _repository.fetchCompatibleTenants(
      ownerId: ownerId,
      propertyId: propertyId,
    );
    // Ignore a stale response if the owner switched property meanwhile.
    if (isClosed || propertyId != state.selectedPropertyId) return;
    emit(state.copyWith(isLoading: false, tenants: tenants));
  }

  @override
  void emit(FindTenantsState state) {
    if (isClosed) return; // async work may outlive the cubit
    super.emit(state);
  }

  String _message(Object e) => e.toString().replaceFirst('Exception: ', '');
}
