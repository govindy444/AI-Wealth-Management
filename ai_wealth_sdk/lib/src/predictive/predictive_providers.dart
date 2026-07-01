import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import 'data/datasources/predictive_remote_datasource.dart';
import 'data/repositories/predictive_repository_impl.dart';
import 'domain/repositories/predictive_repository.dart';
import 'domain/usecases/get_forecast_usecase.dart';
import 'presentation/state/predictive_controller.dart';
import 'presentation/state/predictive_state.dart';

/// DI wiring for the Predictive Banking module (Module 16).
/// A pure consumer of the foundation (remote datasource uses `apiClientProvider`).

final predictiveRemoteDataSourceProvider = Provider<PredictiveRemoteDataSource>(
  (ref) => PredictiveRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final predictiveRepositoryProvider = Provider<PredictiveRepository>(
  (ref) => PredictiveRepositoryImpl(
    remote: ref.watch(predictiveRemoteDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);

final getForecastUseCaseProvider = Provider(
  (ref) => GetForecastUseCase(ref.watch(predictiveRepositoryProvider)),
);

final predictiveControllerProvider =
    StateNotifierProvider<PredictiveController, PredictiveState>(
  (ref) => PredictiveController(
    getForecast: ref.watch(getForecastUseCaseProvider),
  ),
);
