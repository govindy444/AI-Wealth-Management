import '../../../core/network/api_client.dart';
import '../../domain/entities/financial_health.dart';
import '../models/financial_health_dto.dart';

abstract interface class FinancialHealthRemoteDataSource {
  Future<FinancialHealth> getScore();
}

class FinancialHealthRemoteDataSourceImpl
    implements FinancialHealthRemoteDataSource {
  FinancialHealthRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<FinancialHealth> getScore() async {
    final res = await _client.get('/financial-health/score');
    return FinancialHealthDto.fromJson(res.asMap);
  }
}
