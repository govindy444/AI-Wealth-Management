import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/fraud_reports.dart';
import '../repositories/fraud_repository.dart';

class GetFraudAlertsUseCase implements UseCase<FraudAlerts, NoParams> {
  GetFraudAlertsUseCase(this._repository);
  final FraudRepository _repository;

  @override
  FutureResult<FraudAlerts> call(NoParams params) => _repository.getAlerts();
}

class CheckMessageUseCase implements UseCase<MessageCheck, String> {
  CheckMessageUseCase(this._repository);
  final FraudRepository _repository;

  @override
  FutureResult<MessageCheck> call(String text) => _repository.checkMessage(text);
}
