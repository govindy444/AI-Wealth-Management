import '../../domain/entities/avatar_persona.dart';
import '../../domain/entities/avatar_presentation.dart';

class AvatarDtos {
  const AvatarDtos._();

  static AvatarPersona personaFromJson(Map<String, dynamic> j) => AvatarPersona(
        id: (j['id'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        accentColorHex: (j['accent_color'] as String?) ?? '#6C4DF4',
        languages:
            (j['languages'] as List? ?? const ['en']).map((e) => e.toString()).toList(),
        defaultLanguage: (j['default_language'] as String?) ?? 'en',
      );

  static AvatarPresentation presentationFromJson(Map<String, dynamic> j) =>
      AvatarPresentation(
        personaId: (j['persona_id'] as String?) ?? '',
        personaName: (j['persona_name'] as String?) ?? '',
        language: (j['language'] as String?) ?? 'en',
        expression: AvatarExpression.fromWire((j['expression'] as String?) ?? 'neutral'),
        text: (j['text'] as String?) ?? '',
        segments: (j['segments'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(_segmentFromJson)
            .toList(growable: false),
      );

  static AvatarSegment _segmentFromJson(Map<String, dynamic> j) => AvatarSegment(
        text: (j['text'] as String?) ?? '',
        duration: Duration(milliseconds: (j['duration_ms'] as num?)?.toInt() ?? 900),
      );
}
