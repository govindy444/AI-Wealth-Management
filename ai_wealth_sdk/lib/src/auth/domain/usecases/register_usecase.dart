import 'package:equatable/equatable.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.email,
    required this.password,
    required this.fullName,
  });
  final String email;
  final String password;
  final String fullName;
  @override
  List<Object?> get props => [email, password, fullName];
}

class RegisterUseCase implements UseCase<AuthSession, RegisterParams> {
  const RegisterUseCase(this._repo);
  final AuthRepository _repo;

  @override
  FutureResult<AuthSession> call(RegisterParams params) => _repo.register(
        email: params.email,
        password: params.password,
        fullName: params.fullName,
      );
}
