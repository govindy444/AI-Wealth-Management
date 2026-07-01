import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import 'data/datasources/recommendation_remote_datasource.dart';
import 'data/repositories/recommendation_repository_impl.dart';
import 'domain/repositories/recommendation_repository.dart';
import 'domain/usecases/recommendation_usecases.dart';
import 'presentation/state/recommendations_controller.dart';
import 'presentation/state/recommendations_state.dart';

/// DI wiring for the Investment Recommendation module (Module 14).
/// A pure consumer of the foundation (remote datasource uses `apiClientProvider`).

final recommendationRemoteDataSourceProvider =
    Provider<RecommendationRemoteDataSource>(
  (ref) => RecommendationRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final recommendationRepositoryProvider = Provider<RecommendationRepository>(
  (ref) => RecommendationRepositoryImpl(
    remote: ref.watch(recommendationRemoteDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);

final listProductsUseCaseProvider =
    Provider((ref) => ListProductsUseCase(ref.watch(recommendationRepositoryProvider)));
final recommendUseCaseProvider =
    Provider((ref) => RecommendUseCase(ref.watch(recommendationRepositoryProvider)));

final recommendationsControllerProvider =
    StateNotifierProvider<RecommendationsController, RecommendationsState>(
  (ref) => RecommendationsController(
    recommend: ref.watch(recommendUseCaseProvider),
  ),
);
