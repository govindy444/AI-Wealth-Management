import 'package:equatable/equatable.dart';

import '../../domain/entities/avatar_persona.dart';
import '../../domain/entities/avatar_presentation.dart';

enum AvatarStatus { initial, loading, ready, error }


class AvatarState extends Equatable {
  const AvatarState({
    this.status = AvatarStatus.initial,
    this.personas = const [],
    this.selectedPersonaId,
    this.language = 'en',
    this.presentation,
    this.currentSegment = 0,
    this.speaking = false,
    this.errorMessage,
  });

  final AvatarStatus status;
  final List<AvatarPersona> personas;
  final String? selectedPersonaId;
  final String language;
  final AvatarPresentation? presentation;
  final int currentSegment;
  final bool speaking;
  final String? errorMessage;

  const AvatarState.initial() : this();

  bool get isLoading => status == AvatarStatus.loading;

  AvatarPersona? get selectedPersona {
    for (final p in personas) {
      if (p.id == selectedPersonaId) return p;
    }
    return personas.isNotEmpty ? personas.first : null;
  }

  AvatarExpression get expression =>
      presentation?.expression ?? AvatarExpression.neutral;

  String? get currentCaption {
    final segments = presentation?.segments;
    if (segments == null || segments.isEmpty) return null;
    if (currentSegment < 0 || currentSegment >= segments.length) return null;
    return segments[currentSegment].text;
  }

  AvatarState copyWith({
    AvatarStatus? status,
    List<AvatarPersona>? personas,
    String? selectedPersonaId,
    String? language,
    AvatarPresentation? presentation,
    int? currentSegment,
    bool? speaking,
    String? errorMessage,
    bool clearError = false,
    bool clearPresentation = false,
  }) {
    return AvatarState(
      status: status ?? this.status,
      personas: personas ?? this.personas,
      selectedPersonaId: selectedPersonaId ?? this.selectedPersonaId,
      language: language ?? this.language,
      presentation:
          clearPresentation ? null : (presentation ?? this.presentation),
      currentSegment: currentSegment ?? this.currentSegment,
      speaking: speaking ?? this.speaking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        personas,
        selectedPersonaId,
        language,
        presentation,
        currentSegment,
        speaking,
        errorMessage,
      ];
}
