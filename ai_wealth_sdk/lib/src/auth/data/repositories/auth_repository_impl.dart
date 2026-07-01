import '../../../core/data/base_repository.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/logging/sdk_logger.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';


class AuthRepositoryImpl with BaseRepository implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required this.logger,
  })  : _remote = remote,
        _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  final SdkLogger logger;

  @override
  FutureResult<AuthSession> login({
    required String email,
    required String password,
  }) =>
      guard(() async {
        final dto = await _remote.login(email, password);
        final session = dto.toSession();
        await _local.cacheSession(session);
        logger.info('Login succeeded', data: session.user.id);
        return session;
      });

  @override
  FutureResult<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
  }) =>
      guard(() async {
        final dto = await _remote.register(email, password, fullName);
        final session = dto.toSession();
        await _local.cacheSession(session);
        return session;
      });

  @override
  FutureResult<AuthSession> refresh() => guard(() async {
        final current = await _local.readSession();
        if (current == null) {
          throw AuthException('No session to refresh.', code: 'no_session');
        }
        final dto = await _remote.refresh(current.refreshToken);
        final session = dto.toSession();
        await _local.cacheSession(session);
        return session;
      });

  @override
  FutureResult<void> logout() => guard(() async {
        try {
          await _remote.logout();
        } catch (_) {
         
        }
        await _local.clear();
      });

  @override
  FutureResult<AuthSession?> currentSession() => guard(() async {
        try {
          return await _local.readSession();
        } on CacheException {
          await _local.clear();
          return null;
        }
      });
}
