import '../../../core/utils/result.dart';
import '../entities/fraud_reports.dart';


abstract interface class FraudRepository {
  FutureResult<FraudAlerts> getAlerts();

  FutureResult<MessageCheck> checkMessage(String text);
}
