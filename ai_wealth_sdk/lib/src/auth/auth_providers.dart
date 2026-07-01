import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import '../core/network/token_provider.dart';
import '../network/network_providers.dart';
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/session_token_provider.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'domain/usecases/session_usecases.dart';
import 'presentation/state/auth_controller.dart';
import 'presentation/state/auth_state.dart';


final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSourceImpl(ref.watch(secureStoreProvider)),
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(authLocalDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);


final _refreshRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(ref.watch(refreshApiClientProvider)),
);


final sessionTokenProviderProvider = Provider<TokenProvider>(
  (ref) => SessionTokenProvider(
    local: ref.watch(authLocalDataSourceProvider),
    remote: ref.watch(_refreshRemoteDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);


final Override authTokenProviderOverride =
    tokenProviderProvider.overrideWith((ref) => ref.watch(sessionTokenProviderProvider));

final loginUseCaseProvider =
    Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));
final registerUseCaseProvider =
    Provider((ref) => RegisterUseCase(ref.watch(authRepositoryProvider)));
final logoutUseCaseProvider =
    Provider((ref) => LogoutUseCase(ref.watch(authRepositoryProvider)));
final getCurrentSessionUseCaseProvider =
    Provider((ref) => GetCurrentSessionUseCase(ref.watch(authRepositoryProvider)));

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(
    login: ref.watch(loginUseCaseProvider),
    register: ref.watch(registerUseCaseProvider),
    logout: ref.watch(logoutUseCaseProvider),
    currentSession: ref.watch(getCurrentSessionUseCaseProvider),
  ),
);
