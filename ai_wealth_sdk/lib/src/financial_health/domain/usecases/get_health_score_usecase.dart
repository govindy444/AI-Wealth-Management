import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/financial_health.dart';
import '../repositories/financial_health_repository.dart';

class GetHealthScoreUseCase implements UseCase<FinancialHealth, NoParams> {
  GetHealthScoreUseCase(this._repository);
  final FinancialHealthRepository _repository;

  @override
  FutureResult<FinancialHealth> call(NoParams params) => _repository.getScore();
}
