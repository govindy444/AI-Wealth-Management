import '../../../core/utils/result.dart';
import '../entities/holding.dart';
import '../entities/portfolio_summary.dart';

/// Portfolio Intelligence repository contract.
abstract interface class PortfolioRepository {
  FutureResult<PortfolioSummary> getSummary();
  FutureResult<List<Holding>> getHoldings();
}
