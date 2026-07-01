import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/sdk_providers.dart';
import 'data/datasources/profile_remote_datasource.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/usecases/profile_usecases.dart';
import 'presentation/state/profile_controller.dart';
import 'presentation/state/profile_state.dart';

/// DI wiring for the Profile & Settings module (Module 19).
/// A pure consumer of the foundation (remote datasource uses `apiClientProvider`).

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => ProfileRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    remote: ref.watch(profileRemoteDataSourceProvider),
    logger: ref.watch(sdkLoggerProvider),
  ),
);

final getProfileUseCaseProvider =
    Provider((ref) => GetProfileUseCase(ref.watch(profileRepositoryProvider)));
final updateProfileUseCaseProvider =
    Provider((ref) => UpdateProfileUseCase(ref.watch(profileRepositoryProvider)));
final updatePreferencesUseCaseProvider = Provider(
    (ref) => UpdatePreferencesUseCase(ref.watch(profileRepositoryProvider)));

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>(
  (ref) => ProfileController(
    getProfile: ref.watch(getProfileUseCaseProvider),
    updateProfile: ref.watch(updateProfileUseCaseProvider),
    updatePreferences: ref.watch(updatePreferencesUseCaseProvider),
  ),
);
