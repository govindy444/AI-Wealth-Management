import '../../../core/network/api_client.dart';
import '../../domain/entities/investment_product.dart';
import '../../domain/entities/recommendation.dart';
import '../models/recommendation_dtos.dart';

/// Talks to the backend `/recommendations` endpoints via the [ApiClient].
abstract interface class RecommendationRemoteDataSource {
  Future<List<InvestmentProduct>> listProducts();
  Future<RecommendationSet> recommend({
    required String riskProfile,
    required double amount,
    required int horizonYears,
  });
}

class RecommendationRemoteDataSourceImpl
    implements RecommendationRemoteDataSource {
  RecommendationRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<List<InvestmentProduct>> listProducts() async {
    final res = await _client.get('/recommendations/products');
    return res.asList
        .cast<Map<String, dynamic>>()
        .map(RecommendationDtos.productFromJson)
        .toList(growable: false);
  }

  @override
  Future<RecommendationSet> recommend({
    required String riskProfile,
    required double amount,
    required int horizonYears,
  }) async {
    final res = await _client.post('/recommendations', data: {
      'risk_profile': riskProfile,
      'amount': amount,
      'horizon_years': horizonYears,
    });
    return RecommendationDtos.setFromJson(res.asMap);
  }
}
