import 'dart:convert';

import '../../../core/error/exceptions.dart';
import '../../../core/storage/secure_store.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';


abstract interface class AuthLocalDataSource {
  Future<void> cacheSession(AuthSession session);
  Future<AuthSession?> readSession();
  Future<void> clear();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._store);

  static const _key = 'wealth_sdk.auth.session';
  final SecureStore _store;

  @override
  Future<void> cacheSession(AuthSession session) async {
    try {
      final map = {
        'access_token': session.accessToken,
        'refresh_token': session.refreshToken,
        'expires_at': session.expiresAt.toIso8601String(),
        'user': {
          'id': session.user.id,
          'email': session.user.email,
          'full_name': session.user.fullName,
          'roles': session.user.roles,
        },
      };
      await _store.write(_key, jsonEncode(map));
    } catch (e) {
      throw CacheException('Failed to persist session: $e');
    }
  }

  @override
  Future<AuthSession?> readSession() async {
    try {
      final raw = await _store.read(_key);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final user = map['user'] as Map<String, dynamic>;
      return AuthSession(
        accessToken: map['access_token'] as String,
        refreshToken: map['refresh_token'] as String,
        expiresAt: DateTime.parse(map['expires_at'] as String),
        user: AuthUser(
          id: user['id'] as String,
          email: user['email'] as String,
          fullName: (user['full_name'] as String?) ?? '',
          roles: (user['roles'] as List?)?.cast<String>() ?? const ['customer'],
        ),
      );
    } catch (e) {
      throw CacheException('Failed to read session: $e');
    }
  }

  @override
  Future<void> clear() => _store.delete(_key);
}
