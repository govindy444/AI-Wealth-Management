import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';


class TokenResponseDto {
  const TokenResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn; 
  final AuthUserDto user;

  factory TokenResponseDto.fromJson(Map<String, dynamic> json) {
    return TokenResponseDto(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: (json['token_type'] as String?) ?? 'bearer',
      expiresIn: (json['expires_in'] as num).toInt(),
      user: AuthUserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  AuthSession toSession() => AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user.toEntity(),
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      );
}

class AuthUserDto {
  const AuthUserDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roles,
  });

  final String id;
  final String email;
  final String fullName;
  final List<String> roles;

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      roles: (json['roles'] as List?)?.cast<String>() ?? const ['customer'],
    );
  }

  AuthUser toEntity() =>
      AuthUser(id: id, email: email, fullName: fullName, roles: roles);
}
