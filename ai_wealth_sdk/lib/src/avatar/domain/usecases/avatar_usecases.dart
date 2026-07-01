import 'package:equatable/equatable.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/avatar_persona.dart';
import '../entities/avatar_presentation.dart';
import '../repositories/avatar_repository.dart';

class ListPersonasUseCase implements UseCase<List<AvatarPersona>, NoParams> {
  ListPersonasUseCase(this._repository);
  final AvatarRepository _repository;

  @override
  FutureResult<List<AvatarPersona>> call(NoParams params) =>
      _repository.listPersonas();
}

class PresentParams extends Equatable {
  const PresentParams({this.text, this.personaId, this.language});
  final String? text;
  final String? personaId;
  final String? language;

  @override
  List<Object?> get props => [text, personaId, language];
}

class PresentUseCase implements UseCase<AvatarPresentation, PresentParams> {
  PresentUseCase(this._repository);
  final AvatarRepository _repository;

  @override
  FutureResult<AvatarPresentation> call(PresentParams params) =>
      _repository.present(
        text: params.text,
        personaId: params.personaId,
        language: params.language,
      );
}
