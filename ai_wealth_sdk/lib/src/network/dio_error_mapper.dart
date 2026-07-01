import 'package:dio/dio.dart';

import '../core/error/exceptions.dart';

/// Translates a low-level [DioException] into one of the SDK's transport
/// exceptions, parsing the backend error envelope
/// `{"error": {code, message, details}}` when present.
///
/// Repositories then map these to typed `Failure`s via `BaseRepository.guard`,
/// so neither Dio nor HTTP details leak past the data layer.
Exception mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return NetworkException('The request timed out. Please try again.');
    case DioExceptionType.connectionError:
      return NetworkException('No internet connection.');
    case DioExceptionType.cancel:
      return NetworkException('The request was cancelled.');
    case DioExceptionType.badCertificate:
      return NetworkException('Insecure connection (bad certificate).');
    case DioExceptionType.badResponse:
      return _fromResponse(e.response);
    case DioExceptionType.unknown:
    default:
      return NetworkException(e.message ?? 'Unexpected network error.');
  }
}

Exception _fromResponse(Response? response) {
  final status = response?.statusCode ?? 0;
  final parsed = _parseEnvelope(response?.data);
  final message = parsed.$1;
  final code = parsed.$2;

  if (status == 401) {
    return AuthException(message ?? 'Authentication required.', code: code);
  }
  if (status == 403) {
    return AuthException(message ?? 'You do not have access.', code: code ?? 'forbidden');
  }
  return ServerException(
    message ?? 'Server error ($status).',
    statusCode: status,
    code: code,
  );
}

/// Returns (message, code) from a backend error envelope, tolerating shapes that
/// don't match (returns nulls so callers fall back to defaults).
(String?, String?) _parseEnvelope(dynamic data) {
  if (data is Map) {
    final error = data['error'];
    if (error is Map) {
      return (error['message'] as String?, error['code'] as String?);
    }
    // FastAPI default { "detail": ... } fallback.
    final detail = data['detail'];
    if (detail is String) return (detail, null);
  }
  return (null, null);
}
