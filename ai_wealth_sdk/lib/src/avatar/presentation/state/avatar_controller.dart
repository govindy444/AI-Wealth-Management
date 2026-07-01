import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/use_case.dart';
import '../../domain/usecases/avatar_usecases.dart';
import 'avatar_state.dart';


class AvatarController extends StateNotifier<AvatarState> {
  AvatarController({
    required ListPersonasUseCase listPersonas,
    required PresentUseCase present,
  })  : _listPersonas = listPersonas,
        _present = present,
        super(const AvatarState.initial());

  final ListPersonasUseCase _listPersonas;
  final PresentUseCase _present;

  Timer? _segmentTimer;

  Future<void> init() async {
    if (state.status == AvatarStatus.loading) return;
    state = state.copyWith(status: AvatarStatus.loading, clearError: true);
    final result = await _listPersonas(const NoParams());
    state = result.fold(
      (failure) => state.copyWith(
        status: AvatarStatus.error,
        errorMessage: failure.message,
      ),
      (personas) {
        final first = personas.isNotEmpty ? personas.first : null;
        return state.copyWith(
          status: AvatarStatus.ready,
          personas: personas,
          selectedPersonaId: first?.id,
          language: first?.defaultLanguage ?? 'en',
        );
      },
    );
  }

  void selectPersona(String personaId) {
    _stopPlayback();
    final persona = state.personas.firstWhere(
      (p) => p.id == personaId,
      orElse: () => state.personas.first,
    );
    final language = persona.supports(state.language)
        ? state.language
        : persona.defaultLanguage;
    state = state.copyWith(
      selectedPersonaId: personaId,
      language: language,
      clearPresentation: true,
      speaking: false,
      currentSegment: 0,
    );
  }

  void selectLanguage(String language) {
    _stopPlayback();
    state = state.copyWith(
      language: language,
      clearPresentation: true,
      speaking: false,
      currentSegment: 0,
    );
  }

  Future<void> speak({String? text}) async {
    _stopPlayback();
    state = state.copyWith(status: AvatarStatus.loading, clearError: true);

    final result = await _present(PresentParams(
      text: text,
      personaId: state.selectedPersonaId,
      language: state.language,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        status: AvatarStatus.error,
        errorMessage: failure.message,
      ),
      (presentation) {
        state = state.copyWith(
          status: AvatarStatus.ready,
          presentation: presentation,
          currentSegment: 0,
          speaking: presentation.segments.isNotEmpty,
        );
        if (presentation.segments.isNotEmpty) _scheduleSegment(0);
      },
    );
  }

  void stop() {
    _stopPlayback();
    if (mounted) state = state.copyWith(speaking: false);
  }

  void _scheduleSegment(int index) {
    final segments = state.presentation?.segments;
    if (segments == null || index >= segments.length) {
      if (mounted) state = state.copyWith(speaking: false);
      return;
    }
    if (mounted) state = state.copyWith(currentSegment: index, speaking: true);
    _segmentTimer = Timer(segments[index].duration, () => _scheduleSegment(index + 1));
  }

  void _stopPlayback() {
    _segmentTimer?.cancel();
    _segmentTimer = null;
  }

  @override
  void dispose() {
    _stopPlayback();
    super.dispose();
  }
}
