import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/use_case.dart';
import '../../domain/usecases/portfolio_usecases.dart';
import 'portfolio_state.dart';

/// Drives the portfolio screen: loads and reduces the summary.
class PortfolioController extends StateNotifier<PortfolioState> {
  PortfolioController({required GetPortfolioSummaryUseCase getSummary})
      : _getSummary = getSummary,
        super(const PortfolioState.initial());

  final GetPortfolioSummaryUseCase _getSummary;

  Future<void> load() async {
    state = state.copyWith(status: PortfolioStatus.loading, clearError: true);
    final result = await _getSummary(const NoParams());
    state = result.fold(
      (failure) => state.copyWith(
        status: PortfolioStatus.error,
        errorMessage: failure.message,
      ),
      (summary) => PortfolioState(
        status: PortfolioStatus.ready,
        summary: summary,
      ),
    );
  }

  Future<void> refresh() => load();
}
