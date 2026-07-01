import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import 'data/datasources/spending_remote_datasource.dart';
import 'data/repositories/spending_repository_impl.dart';
import 'domain/repositories/spending_repository.dart';
import 'domain/usecases/spending_usecases.dart';
import 'presentation/state/spending_controller.dart';
import 'presentation/state/spending_state.dart';

/// DI wiring for the Spending Analytics module (Module 11).
///
/// A pure consumer of the foundation: the remote datasource uses
/// `apiClientProvider` (Module 5). No overrides required.

final spendingRemoteDataSourceProvider = Provider<SpendingRemoteDataSource>(
  (ref) => SpendingRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final spendingRepositoryProvider = Provider<SpendingRepository>(
  (ref) => SpendingRepositoryImpl(
    remote: ref.watch(spendingRemoteDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);

final getSpendingSummaryUseCaseProvider = Provider<GetSpendingSummaryUseCase>(
  (ref) => GetSpendingSummaryUseCase(ref.watch(spendingRepositoryProvider)),
);
final getBudgetsUseCaseProvider = Provider<GetBudgetsUseCase>(
  (ref) => GetBudgetsUseCase(ref.watch(spendingRepositoryProvider)),
);
final getTransactionsUseCaseProvider = Provider<GetTransactionsUseCase>(
  (ref) => GetTransactionsUseCase(ref.watch(spendingRepositoryProvider)),
);
final setBudgetUseCaseProvider = Provider<SetBudgetUseCase>(
  (ref) => SetBudgetUseCase(ref.watch(spendingRepositoryProvider)),
);

final spendingControllerProvider =
    StateNotifierProvider<SpendingController, SpendingState>(
  (ref) => SpendingController(
    getSummary: ref.watch(getSpendingSummaryUseCaseProvider),
    getBudgets: ref.watch(getBudgetsUseCaseProvider),
    setBudget: ref.watch(setBudgetUseCaseProvider),
  ),
);
