import '../../../core/utils/result.dart';
import '../entities/financial_health.dart';

abstract interface class FinancialHealthRepository {
  FutureResult<FinancialHealth> getScore();
}
