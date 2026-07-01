import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import 'data/datasources/financial_health_remote_datasource.dart';
import 'data/repositories/financial_health_repository_impl.dart';
import 'domain/repositories/financial_health_repository.dart';
import 'domain/usecases/get_health_score_usecase.dart';
import 'presentation/state/financial_health_controller.dart';
import 'presentation/state/financial_health_state.dart';



final financialHealthRemoteDataSourceProvider =
    Provider<FinancialHealthRemoteDataSource>(
  (ref) => FinancialHealthRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final financialHealthRepositoryProvider = Provider<FinancialHealthRepository>(
  (ref) => FinancialHealthRepositoryImpl(
    remote: ref.watch(financialHealthRemoteDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);

final getHealthScoreUseCaseProvider = Provider<GetHealthScoreUseCase>(
  (ref) => GetHealthScoreUseCase(ref.watch(financialHealthRepositoryProvider)),
);

final financialHealthControllerProvider =
    StateNotifierProvider<FinancialHealthController, FinancialHealthState>(
  (ref) => FinancialHealthController(
    getScore: ref.watch(getHealthScoreUseCaseProvider),
  ),
);
