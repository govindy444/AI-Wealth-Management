import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../models/token_response_dto.dart';

abstract interface class AuthRemoteDataSource {
  Future<TokenResponseDto> login(String email, String password);
  Future<TokenResponseDto> register(String email, String password, String fullName);
  Future<TokenResponseDto> refresh(String refreshToken);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<TokenResponseDto> login(String email, String password) async {
    final res = await _client.post(
      '/auth/login',
      data: {'email': email, 'password': password},
      requiresAuth: false,
    );
    return TokenResponseDto.fromJson(res.asMap);
  }

  @override
  Future<TokenResponseDto> register(
      String email, String password, String fullName) async {
    final res = await _client.post(
      '/auth/register',
      data: {'email': email, 'password': password, 'full_name': fullName},
      requiresAuth: false,
    );
    return TokenResponseDto.fromJson(res.asMap);
  }

  @override
  Future<TokenResponseDto> refresh(String refreshToken) async {
    final res = await _client.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
      requiresAuth: false,
    );
    return TokenResponseDto.fromJson(res.asMap);
  }

  @override
  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } on AuthException {
    }
  }
}
