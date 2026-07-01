import '../../../core/utils/result.dart';
import '../entities/forecast.dart';

/// Predictive Banking repository contract.
abstract interface class PredictiveRepository {
  FutureResult<Forecast> getForecast();
}
