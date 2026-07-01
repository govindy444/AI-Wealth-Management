import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import 'data/datasources/avatar_remote_datasource.dart';
import 'data/repositories/avatar_repository_impl.dart';
import 'domain/repositories/avatar_repository.dart';
import 'domain/usecases/avatar_usecases.dart';
import 'presentation/state/avatar_controller.dart';
import 'presentation/state/avatar_state.dart';



final avatarRemoteDataSourceProvider = Provider<AvatarRemoteDataSource>(
  (ref) => AvatarRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final avatarRepositoryProvider = Provider<AvatarRepository>(
  (ref) => AvatarRepositoryImpl(
    remote: ref.watch(avatarRemoteDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);

final listPersonasUseCaseProvider = Provider<ListPersonasUseCase>(
  (ref) => ListPersonasUseCase(ref.watch(avatarRepositoryProvider)),
);
final presentUseCaseProvider = Provider<PresentUseCase>(
  (ref) => PresentUseCase(ref.watch(avatarRepositoryProvider)),
);


final avatarControllerProvider =
    StateNotifierProvider.autoDispose<AvatarController, AvatarState>(
  (ref) => AvatarController(
    listPersonas: ref.watch(listPersonasUseCaseProvider),
    present: ref.watch(presentUseCaseProvider),
  ),
);
