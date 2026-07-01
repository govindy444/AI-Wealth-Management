import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import 'data/datasources/fraud_remote_datasource.dart';
import 'data/repositories/fraud_repository_impl.dart';
import 'domain/repositories/fraud_repository.dart';
import 'domain/usecases/fraud_usecases.dart';
import 'presentation/state/fraud_controller.dart';
import 'presentation/state/fraud_state.dart';



final fraudRemoteDataSourceProvider = Provider<FraudRemoteDataSource>(
  (ref) => FraudRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final fraudRepositoryProvider = Provider<FraudRepository>(
  (ref) => FraudRepositoryImpl(
    remote: ref.watch(fraudRemoteDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);

final getFraudAlertsUseCaseProvider =
    Provider((ref) => GetFraudAlertsUseCase(ref.watch(fraudRepositoryProvider)));
final checkMessageUseCaseProvider =
    Provider((ref) => CheckMessageUseCase(ref.watch(fraudRepositoryProvider)));

final fraudControllerProvider =
    StateNotifierProvider<FraudController, FraudState>(
  (ref) => FraudController(
    getAlerts: ref.watch(getFraudAlertsUseCaseProvider),
    checkMessage: ref.watch(checkMessageUseCaseProvider),
  ),
);
