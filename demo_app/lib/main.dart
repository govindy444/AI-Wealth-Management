import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/theme/theme_controller.dart';
import 'features/voice/platform_speech.dart';

const _apiBaseUrl = 'https://wealth.govzen.tech/api/v1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sdk = WealthSdk.initialize(
    WealthSdkConfig(
      apiBaseUrl: _apiBaseUrl,
      tenantId: 'idbi-demo',
      environment: WealthSdkEnvironment.sandbox,
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        ...sdk.overrides,
        sharedPreferencesProvider.overrideWithValue(prefs),
        speechRecognizerProvider.overrideWithValue(PlatformSpeechRecognizer()),
        speechSynthesizerProvider.overrideWithValue(PlatformSpeechSynthesizer()),
      ],
      child: const DemoBankApp(),
    ),
  );
}
