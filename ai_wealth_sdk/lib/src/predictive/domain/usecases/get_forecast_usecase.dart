import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/forecast.dart';
import '../repositories/predictive_repository.dart';

/// Loads the user's cashflow forecast.
class GetForecastUseCase implements UseCase<Forecast, NoParams> {
  GetForecastUseCase(this._repository);
  final PredictiveRepository _repository;

  @override
  FutureResult<Forecast> call(NoParams params) => _repository.getForecast();
}
