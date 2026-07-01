import '../../../core/utils/result.dart';
import '../entities/auth_session.dart';


abstract interface class AuthRepository {
  FutureResult<AuthSession> login({
    required String email,
    required String password,
  });

  FutureResult<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
  });

  FutureResult<AuthSession> refresh();

  FutureResult<void> logout();

  FutureResult<AuthSession?> currentSession();
}
