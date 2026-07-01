import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import 'data/datasources/portfolio_remote_datasource.dart';
import 'data/repositories/portfolio_repository_impl.dart';
import 'domain/repositories/portfolio_repository.dart';
import 'domain/usecases/portfolio_usecases.dart';
import 'presentation/state/portfolio_controller.dart';
import 'presentation/state/portfolio_state.dart';

/// DI wiring for the Portfolio Intelligence module (Module 15).
/// A pure consumer of the foundation (remote datasource uses `apiClientProvider`).

final portfolioRemoteDataSourceProvider = Provider<PortfolioRemoteDataSource>(
  (ref) => PortfolioRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final portfolioRepositoryProvider = Provider<PortfolioRepository>(
  (ref) => PortfolioRepositoryImpl(
    remote: ref.watch(portfolioRemoteDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);

final getPortfolioSummaryUseCaseProvider = Provider(
  (ref) => GetPortfolioSummaryUseCase(ref.watch(portfolioRepositoryProvider)),
);
final getHoldingsUseCaseProvider = Provider(
  (ref) => GetHoldingsUseCase(ref.watch(portfolioRepositoryProvider)),
);

final portfolioControllerProvider =
    StateNotifierProvider<PortfolioController, PortfolioState>(
  (ref) => PortfolioController(
    getSummary: ref.watch(getPortfolioSummaryUseCaseProvider),
  ),
);
