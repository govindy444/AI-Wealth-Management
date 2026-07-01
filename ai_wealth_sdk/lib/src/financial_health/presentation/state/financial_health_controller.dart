import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/use_case.dart';
import '../../domain/usecases/get_health_score_usecase.dart';
import 'financial_health_state.dart';

class FinancialHealthController extends StateNotifier<FinancialHealthState> {
  FinancialHealthController({required GetHealthScoreUseCase getScore})
      : _getScore = getScore,
        super(const FinancialHealthState.initial());

  final GetHealthScoreUseCase _getScore;

  Future<void> load() async {
    state = state.copyWith(status: HealthScoreStatus.loading, clearError: true);
    final result = await _getScore(const NoParams());
    state = result.fold(
      (failure) => state.copyWith(
        status: HealthScoreStatus.error,
        errorMessage: failure.message,
      ),
      (health) => FinancialHealthState(
        status: HealthScoreStatus.ready,
        health: health,
      ),
    );
  }

  Future<void> refresh() => load();
}
