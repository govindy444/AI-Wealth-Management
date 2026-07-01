import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/session_usecases.dart';
import 'auth_state.dart';


class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required LoginUseCase login,
    required RegisterUseCase register,
    required LogoutUseCase logout,
    required GetCurrentSessionUseCase currentSession,
  })  : _login = login,
        _register = register,
        _logout = logout,
        _currentSession = currentSession,
        super(const AuthState.unknown());

  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;
  final GetCurrentSessionUseCase _currentSession;

  Future<void> bootstrap() async {
    final result = await _currentSession(const NoParams());
    result.fold(
      (_) => state = state.copyWith(status: AuthStatus.unauthenticated),
      (session) => state = session == null
          ? state.copyWith(status: AuthStatus.unauthenticated)
          : state.copyWith(status: AuthStatus.authenticated, session: session),
    );
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);
    final result = await _login(LoginParams(email: email, password: password));
    return _reduce(result);
  }

  Future<bool> register(String email, String password, String fullName) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);
    final result = await _register(
      RegisterParams(email: email, password: password, fullName: fullName),
    );
    return _reduce(result);
  }

  Future<void> logout() async {
    await _logout(const NoParams());
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  bool _reduce(Result<AuthSession> result) {
    return result.fold(
      (Failure f) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: f.message,
          clearSession: true,
        );
        return false;
      },
      (session) {
        state = AuthState(status: AuthStatus.authenticated, session: session);
        return true;
      },
    );
  }
}
