import '../../core/logging/sdk_logger.dart';
import '../../core/network/token_provider.dart';
import '../domain/entities/auth_session.dart';
import 'datasources/auth_local_datasource.dart';
import 'datasources/auth_remote_datasource.dart';


class SessionTokenProvider implements TokenProvider {
  SessionTokenProvider({
    required AuthLocalDataSource local,
    required AuthRemoteDataSource remote,
    required this.logger,
  })  : _local = local,
        _remote = remote;

  final AuthLocalDataSource _local;
  final AuthRemoteDataSource _remote;
  final SdkLogger logger;

  @override
  Future<String?> accessToken() async {
    final session = await _safeRead();
    if (session == null) return null;
    if (session.isAccessExpired) {
      return await refresh();
    }
    return session.accessToken;
  }

  @override
  Future<String?> refresh() async {
    final session = await _safeRead();
    if (session == null) return null;
    try {
      final dto = await _remote.refresh(session.refreshToken);
      final refreshed = dto.toSession();
      await _local.cacheSession(refreshed);
      return refreshed.accessToken;
    } catch (e) {
      logger.warning('Token refresh failed; clearing session', data: '$e');
      await _local.clear();
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async => (await _safeRead()) != null;

  Future<AuthSession?> _safeRead() async {
    try {
      return await _local.readSession();
    } catch (_) {
      return null;
    }
  }
}
