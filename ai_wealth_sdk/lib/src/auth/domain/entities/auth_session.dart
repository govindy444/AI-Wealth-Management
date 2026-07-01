import 'package:equatable/equatable.dart';

import 'auth_user.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  final DateTime expiresAt;

  bool get isAccessExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 15)));

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    AuthUser? user,
    DateTime? expiresAt,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, user, expiresAt];
}
