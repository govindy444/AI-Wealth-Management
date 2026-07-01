import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/use_case.dart';
import '../../domain/usecases/get_forecast_usecase.dart';
import 'predictive_state.dart';

/// Drives the predictive screen: loads and reduces the forecast.
class PredictiveController extends StateNotifier<PredictiveState> {
  PredictiveController({required GetForecastUseCase getForecast})
      : _getForecast = getForecast,
        super(const PredictiveState.initial());

  final GetForecastUseCase _getForecast;

  Future<void> load() async {
    state = state.copyWith(status: PredictiveStatus.loading, clearError: true);
    final result = await _getForecast(const NoParams());
    state = result.fold(
      (failure) => state.copyWith(
        status: PredictiveStatus.error,
        errorMessage: failure.message,
      ),
      (forecast) => PredictiveState(
        status: PredictiveStatus.ready,
        forecast: forecast,
      ),
    );
  }

  Future<void> refresh() => load();
}
