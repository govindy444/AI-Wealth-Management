import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/get_dashboard_usecase.dart';
import 'dashboard_state.dart';


class DashboardController extends StateNotifier<DashboardState> {
  DashboardController({required GetDashboardUseCase getDashboard})
      : _getDashboard = getDashboard,
        super(const DashboardState.initial());

  final GetDashboardUseCase _getDashboard;

 
  Future<void> load({bool forceRefresh = false}) async {
    state = state.copyWith(status: DashboardStatus.loading, clearError: true);
    final result = await _getDashboard(
      GetDashboardParams(forceRefresh: forceRefresh),
    );
    state = result.fold(
      (failure) => state.copyWith(
        status: DashboardStatus.error,
        errorMessage: failure.message,
      ),
      (summary) => DashboardState(
        status: DashboardStatus.ready,
        summary: summary,
      ),
    );
  }

  Future<void> refresh() => load(forceRefresh: true);
}
