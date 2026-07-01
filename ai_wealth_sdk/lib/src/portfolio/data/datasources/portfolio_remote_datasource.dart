import '../../../core/network/api_client.dart';
import '../../domain/entities/holding.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../models/portfolio_dtos.dart';

/// Talks to the backend `/portfolio` endpoints via the [ApiClient].
abstract interface class PortfolioRemoteDataSource {
  Future<PortfolioSummary> getSummary();
  Future<List<Holding>> getHoldings();
}

class PortfolioRemoteDataSourceImpl implements PortfolioRemoteDataSource {
  PortfolioRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<PortfolioSummary> getSummary() async {
    final res = await _client.get('/portfolio/summary');
    return PortfolioDtos.summaryFromJson(res.asMap);
  }

  @override
  Future<List<Holding>> getHoldings() async {
    final res = await _client.get('/portfolio/holdings');
    return res.asList
        .cast<Map<String, dynamic>>()
        .map(PortfolioDtos.holdingFromJson)
        .toList(growable: false);
  }
}
