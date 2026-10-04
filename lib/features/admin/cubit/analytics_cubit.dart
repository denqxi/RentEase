import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore/models/models.dart';
import '../domain/entities/admin_entities.dart';
import '../domain/repositories/admin_repository.dart';

class AnalyticsState extends Equatable {
  const AnalyticsState({
    this.isLoading = true,
    this.stats,
    this.logs = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final AdminStats? stats;
  final List<AdminLogDoc> logs;
  final String? errorMessage;

  @override
  List<Object?> get props => [isLoading, stats, logs, errorMessage];
}

/// Dashboard: one-shot count() aggregates (pull to refresh) plus a live feed
/// of the latest admin actions.
class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit(this._repo) : super(const AnalyticsState());

  final AdminRepository _repo;
  StreamSubscription<List<AdminLogDoc>>? _logSub;

  Future<void> start() async {
    _logSub?.cancel();
    _logSub = _repo.watchRecentLogs().listen(
      (logs) => emit(
        AnalyticsState(
          isLoading: state.isLoading,
          stats: state.stats,
          logs: logs,
          errorMessage: state.errorMessage,
        ),
      ),
      onError: (_) {},
    );
    await refresh();
  }

  Future<void> refresh() async {
    emit(
      AnalyticsState(
        isLoading: state.stats == null,
        stats: state.stats,
        logs: state.logs,
      ),
    );
    try {
      final stats = await _repo.fetchStats();
      emit(AnalyticsState(isLoading: false, stats: stats, logs: state.logs));
    } on AdminException catch (e) {
      emit(
        AnalyticsState(
          isLoading: false,
          stats: state.stats,
          logs: state.logs,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        AnalyticsState(
          isLoading: false,
          stats: state.stats,
          logs: state.logs,
          errorMessage: 'Could not load the dashboard.',
        ),
      );
    }
  }

  Future<void> signOut() => _repo.signOut();

  @override
  Future<void> close() {
    _logSub?.cancel();
    return super.close();
  }
}
