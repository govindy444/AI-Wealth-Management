import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import 'data/datasources/dashboard_local_datasource.dart';
import 'data/datasources/dashboard_remote_datasource.dart';
import 'data/repositories/dashboard_repository_impl.dart';
import 'domain/repositories/dashboard_repository.dart';
import 'domain/usecases/get_dashboard_usecase.dart';
import 'presentation/state/dashboard_controller.dart';
import 'presentation/state/dashboard_state.dart';



final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>(
  (ref) => DashboardRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final dashboardLocalDataSourceProvider = Provider<DashboardLocalDataSource>(
  (ref) => DashboardLocalDataSourceImpl(ref.watch(keyValueStoreProvider)),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(
    remote: ref.watch(dashboardRemoteDataSourceProvider),
    local: ref.watch(dashboardLocalDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);

final getDashboardUseCaseProvider = Provider<GetDashboardUseCase>(
  (ref) => GetDashboardUseCase(ref.watch(dashboardRepositoryProvider)),
);

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>(
  (ref) => DashboardController(
    getDashboard: ref.watch(getDashboardUseCaseProvider),
  ),
);
