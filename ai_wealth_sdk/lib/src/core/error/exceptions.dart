
library;

class ServerException implements Exception {
  ServerException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;
  @override
  String toString() => 'ServerException($statusCode, $code): $message';
}

class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  AuthException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => 'AuthException($code): $message';
}

class CacheException implements Exception {
  CacheException(this.message);
  final String message;
  @override
  String toString() => 'CacheException: $message';
}
