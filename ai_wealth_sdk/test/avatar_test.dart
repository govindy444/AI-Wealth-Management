import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:ai_wealth_sdk/src/avatar/data/datasources/avatar_remote_datasource.dart';
import 'package:ai_wealth_sdk/src/avatar/data/models/avatar_dtos.dart';
import 'package:ai_wealth_sdk/src/avatar/data/repositories/avatar_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

final _logger = SdkLogger(minLevel: SdkLogLevel.error);

Map<String, dynamic> _presentationJson({
  String expression = 'happy',
  List<Map<String, dynamic>>? segments,
}) =>
    {
      'persona_id': 'aanya',
      'persona_name': 'Aanya',
      'language': 'en',
      'expression': expression,
      'text': 'Your net worth grew. Great job!',
      'segments': segments ??
          [
            {'text': 'Your net worth grew.', 'duration_ms': 1200},
            {'text': 'Great job!', 'duration_ms': 900},
          ],
    };

void main() {
  group('AvatarDtos', () {
    test('decodes a persona', () {
      final p = AvatarDtos.personaFromJson({
        'id': 'aanya',
        'name': 'Aanya',
        'title': 'Wealth Advisor',
        'accent_color': '#6C4DF4',
        'languages': ['en', 'hi'],
        'default_language': 'en',
      });
      expect(p.name, 'Aanya');
      expect(p.supports('hi'), isTrue);
      expect(p.supports('ta'), isFalse);
    });

    test('decodes a presentation with timed segments and expression', () {
      final pres = AvatarDtos.presentationFromJson(_presentationJson());
      expect(pres.expression, AvatarExpression.happy);
      expect(pres.segments.length, 2);
      expect(pres.segments.first.duration, const Duration(milliseconds: 1200));
      expect(pres.totalDuration, const Duration(milliseconds: 2100));
    });
  });

  group('AvatarController', () {
    AvatarController controller(FakeRemote remote) {
      final repo = AvatarRepositoryImpl(remote: remote, logger: _logger);
      return AvatarController(
        listPersonas: ListPersonasUseCase(repo),
        present: PresentUseCase(repo),
      );
    }

    test('init loads personas and selects the first as default', () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);

      await c.init();

      expect(c.state.status, AvatarStatus.ready);
      expect(c.state.personas.length, 2);
      expect(c.state.selectedPersonaId, 'aanya');
      expect(c.state.language, 'en');
    });

    test('selecting a persona that lacks the language falls back to its default',
        () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.init();

      c.selectLanguage('ta'); // Aanya supports Tamil
      expect(c.state.language, 'ta');

      c.selectPersona('vikram'); // Vikram does not → fall back to en
      expect(c.state.language, 'en');
    });

    test('speak fetches a presentation and starts playback at segment 0',
        () async {
      final c = controller(FakeRemote());
      addTearDown(c.dispose);
      await c.init();

      await c.speak(text: 'Your net worth grew. Great job!');

      expect(c.state.presentation, isNotNull);
      expect(c.state.expression, AvatarExpression.happy);
      expect(c.state.speaking, isTrue);
      expect(c.state.currentSegment, 0);
      expect(c.state.currentCaption, 'Your net worth grew.');

      c.stop();
      expect(c.state.speaking, isFalse);
    });

    test('surfaces an error when listing personas fails', () async {
      final c = controller(FakeRemote.failing());
      addTearDown(c.dispose);
      await c.init();
      expect(c.state.status, AvatarStatus.error);
      expect(c.state.errorMessage, isNotNull);
    });
  });
}

class FakeRemote implements AvatarRemoteDataSource {
  FakeRemote() : _fail = false;
  FakeRemote.failing() : _fail = true;
  final bool _fail;

  @override
  Future<List<AvatarPersona>> listPersonas() async {
    if (_fail) throw NetworkException('offline');
    return [
      AvatarDtos.personaFromJson({
        'id': 'aanya',
        'name': 'Aanya',
        'title': 'Wealth Advisor',
        'accent_color': '#6C4DF4',
        'languages': ['en', 'hi', 'mr', 'ta', 'bn'],
        'default_language': 'en',
      }),
      AvatarDtos.personaFromJson({
        'id': 'vikram',
        'name': 'Vikram',
        'title': 'Investment Specialist',
        'accent_color': '#0E8F6E',
        'languages': ['en', 'hi', 'mr'],
        'default_language': 'en',
      }),
    ];
  }

  @override
  Future<AvatarPresentation> present({
    String? text,
    String? personaId,
    String? language,
  }) async {
    if (_fail) throw NetworkException('offline');
    return AvatarDtos.presentationFromJson(_presentationJson());
  }
}
