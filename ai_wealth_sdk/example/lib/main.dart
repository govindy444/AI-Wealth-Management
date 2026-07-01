import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';



void main() {
  // Step 1 — initialize with your bank's backend URL and tenant identifier.
  final sdk = WealthSdk.initialize(
    WealthSdkConfig(
      apiBaseUrl: 'https://wealth.govzen.tech/api/v1',
      tenantId: 'my-bank',
    ),
  );

  // Step 2 — install the SDK's Riverpod provider graph into a ProviderScope
  // that wraps the entire app. This is the only required wiring.
  runApp(
    ProviderScope(
      overrides: sdk.overrides,
      child: const ExampleApp(),
    ),
  );
}

