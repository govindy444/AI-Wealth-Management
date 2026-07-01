import 'package:equatable/equatable.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class LoginParams extends Equatable {
  const LoginParams({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

class LoginUseCase implements UseCase<AuthSession, LoginParams> {
  const LoginUseCase(this._repo);
  final AuthRepository _repo;

  @override
  FutureResult<AuthSession> call(LoginParams params) =>
      _repo.login(email: params.email, password: params.password);
}
