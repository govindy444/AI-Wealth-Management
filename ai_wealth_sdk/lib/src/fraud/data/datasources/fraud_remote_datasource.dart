import '../../../core/network/api_client.dart';
import '../../domain/entities/fraud_reports.dart';
import '../models/fraud_dtos.dart';

abstract interface class FraudRemoteDataSource {
  Future<FraudAlerts> getAlerts();
  Future<MessageCheck> checkMessage(String text);
}

class FraudRemoteDataSourceImpl implements FraudRemoteDataSource {
  FraudRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<FraudAlerts> getAlerts() async {
    final res = await _client.get('/fraud/alerts');
    return FraudDtos.alertsFromJson(res.asMap);
  }

  @override
  Future<MessageCheck> checkMessage(String text) async {
    final res = await _client.post('/fraud/check-message', data: {'text': text});
    return FraudDtos.messageCheckFromJson(res.asMap);
  }
}
