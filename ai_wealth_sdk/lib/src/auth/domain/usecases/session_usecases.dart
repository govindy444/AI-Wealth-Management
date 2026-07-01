import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase implements UseCase<void, NoParams> {
  const LogoutUseCase(this._repo);
  final AuthRepository _repo;

  @override
  FutureResult<void> call(NoParams params) => _repo.logout();
}


class GetCurrentSessionUseCase implements UseCase<AuthSession?, NoParams> {
  const GetCurrentSessionUseCase(this._repo);
  final AuthRepository _repo;

  @override
  FutureResult<AuthSession?> call(NoParams params) => _repo.currentSession();
}

class RefreshSessionUseCase implements UseCase<AuthSession, NoParams> {
  const RefreshSessionUseCase(this._repo);
  final AuthRepository _repo;

  @override
  FutureResult<AuthSession> call(NoParams params) => _repo.refresh();
}
