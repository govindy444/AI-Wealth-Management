import '../../../core/network/api_client.dart';
import '../../domain/entities/forecast.dart';
import '../models/predictive_dtos.dart';

/// Talks to the backend `/predictive` endpoints via the [ApiClient].
abstract interface class PredictiveRemoteDataSource {
  Future<Forecast> getForecast();
}

class PredictiveRemoteDataSourceImpl implements PredictiveRemoteDataSource {
  PredictiveRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<Forecast> getForecast() async {
    final res = await _client.get('/predictive/forecast');
    return PredictiveDtos.forecastFromJson(res.asMap);
  }
}
