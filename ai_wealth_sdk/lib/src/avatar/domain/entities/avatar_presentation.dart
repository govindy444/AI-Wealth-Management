import 'package:equatable/equatable.dart';

enum AvatarExpression {
  neutral,
  happy,
  concerned,
  thinking;

  static AvatarExpression fromWire(String value) => switch (value) {
        'happy' => AvatarExpression.happy,
        'concerned' => AvatarExpression.concerned,
        'thinking' => AvatarExpression.thinking,
        _ => AvatarExpression.neutral,
      };
}

class AvatarSegment extends Equatable {
  const AvatarSegment({required this.text, required this.duration});

  final String text;
  final Duration duration;

  @override
  List<Object?> get props => [text, duration];
}


class AvatarPresentation extends Equatable {
  const AvatarPresentation({
    required this.personaId,
    required this.personaName,
    required this.language,
    required this.expression,
    required this.text,
    required this.segments,
  });

  final String personaId;
  final String personaName;
  final String language;
  final AvatarExpression expression;
  final String text;
  final List<AvatarSegment> segments;

  Duration get totalDuration =>
      segments.fold(Duration.zero, (sum, s) => sum + s.duration);

  @override
  List<Object?> get props =>
      [personaId, personaName, language, expression, text, segments];
}
