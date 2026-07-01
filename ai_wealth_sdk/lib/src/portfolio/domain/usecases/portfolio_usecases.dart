import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/holding.dart';
import '../entities/portfolio_summary.dart';
import '../repositories/portfolio_repository.dart';

class GetPortfolioSummaryUseCase implements UseCase<PortfolioSummary, NoParams> {
  GetPortfolioSummaryUseCase(this._repository);
  final PortfolioRepository _repository;

  @override
  FutureResult<PortfolioSummary> call(NoParams params) =>
      _repository.getSummary();
}

class GetHoldingsUseCase implements UseCase<List<Holding>, NoParams> {
  GetHoldingsUseCase(this._repository);
  final PortfolioRepository _repository;

  @override
  FutureResult<List<Holding>> call(NoParams params) => _repository.getHoldings();
}
