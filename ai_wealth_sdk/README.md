# AI Wealth SDK

> Plug-and-play AI wealth advisor, embeddable into any Flutter banking app.

A pure Dart/Flutter package that gives any banking app instant access to
AI-powered wealth advisory: conversational AI, voice assistant, animated avatar,
spending analytics, financial health scoring, goal planning, investment
recommendations, portfolio intelligence, predictive banking, fraud detection,
smart notifications, and analytics — all backed by a provider-agnostic LLM layer
with full offline fallback.

---

## Embed in 3 steps

**1. Add the dependency** in your app's `pubspec.yaml`:

```yaml
dependencies:
  ai_wealth_sdk:
    path: ../packages/ai_wealth_sdk   # or publish to pub.dev
```

**2. Initialize and install** in `main.dart`:

```dart
import 'package:ai_wealth_sdk/ai_wealth_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  final sdk = WealthSdk.initialize(
    const WealthSdkConfig(
      apiBaseUrl: 'https://wealth-ai.yourbank.com/api/v1',
      tenantId: 'your-bank',
    ),
  );

  runApp(
    ProviderScope(
      overrides: sdk.overrides,
      child: const YourBankApp(),
    ),
  );
}
```

**3. Navigate to SDK screens** from your app's router — drop any screen in as a
named route, bottom-nav tab, or modal sheet. Each module is self-contained.

---

## Configuration

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `apiBaseUrl` | `String` | Yes | — | Backend base URL (include `/api/v1` prefix) |
| `tenantId` | `String` | Yes | — | Bank identifier forwarded as a request header |
| `connectTimeout` | `Duration` | No | 30 s | HTTP connect timeout |
| `receiveTimeout` | `Duration` | No | 30 s | HTTP receive timeout |

**Android emulator** — backend running on host machine: `http://10.0.2.2:8099/api/v1`

**Physical device** — use your LAN IP: `http://192.168.x.x:8099/api/v1`

---

## Features

| Module | Controller | Capability |
|---|---|---|
| Authentication | `AuthController` | Register, login, refresh, logout, session management |
| Dashboard | `DashboardController` | Account summary, balance, quick-stats |
| AI Chat | `ChatController` | RAG-grounded conversational AI advisor |
| Voice Assistant | `VoiceController` | STT transcript → AI reply → TTS |
| AI Avatar | `AvatarController` | Indic-language avatar personas + spoken presentations |
| Spending Analytics | `SpendingController` | Transactions, category breakdown, budget alerts |
| Financial Health | `FinancialHealthController` | 5-pillar health score with explanations |
| Goal Planner | `GoalsController` | Create/track goals, SIP simulation, TVM projections |
| Recommendations | `RecommendationsController` | Risk-profiled recommendations with explainability |
| Portfolio | `PortfolioController` | Holdings, allocation, diversification score |
| Predictive Banking | `PredictiveController` | Cash-flow forecast, upcoming bill detection |
| Fraud Detection | `FraudController` | Anomaly alerts, scam-message checker |
| Notifications | `NotificationsController` | Priority notification feed |
| Profile & Settings | `ProfileController` | User profile, preferences, risk tolerance |

Every AI output carries an `Explanation` object — reasoning steps, confidence
score, and key factors — for transparent, auditable decisions.

---

## Architecture

Each module follows clean architecture with three layers:

```
src/<module>/
├── data/
│   ├── datasources/   # HTTP remote sources (via DioApiClient)
│   └── repositories/  # concrete repository implementations
├── domain/
│   ├── entities/      # pure Dart models
│   ├── repositories/  # abstract contracts
│   └── usecases/      # single-responsibility use cases
└── presentation/
    └── state/         # StateNotifier + immutable state (Riverpod)
```

**DI**: Riverpod providers, injected into the host app via `sdk.overrides`.
**Error handling**: `dartz` `Either<Failure, T>` — no exception-driven control flow.
**Network**: Dio with auth interceptor (auto-attaches Bearer token), refresh on 401.
**Storage**: `flutter_secure_storage` for tokens; `shared_preferences` for settings.
**Explainability**: `Explanation` sealed class on every AI use case return type.

---

## Layout

```
lib/
├── ai_wealth_sdk.dart            # single public barrel — the only import needed
└── src/
    ├── wealth_sdk.dart           # WealthSdk entry point + sdk.overrides
    ├── core/
    │   ├── config/               # WealthSdkConfig
    │   ├── di/                   # root SDK providers
    │   ├── domain/               # Explanation contract
    │   ├── error/                # Failure, AppException types
    │   ├── logging/              # SdkLogger
    │   ├── network/              # ApiClient, ApiRequest, ApiResponse, HttpMethod
    │   ├── storage/              # KeyValueStore, SecureStore abstractions
    │   └── utils/                # Result<T>, UseCase base
    ├── network/                  # DioApiClient + network providers
    ├── storage/                  # SharedPreferences + flutter_secure_storage impls
    ├── auth/
    ├── dashboard/
    ├── chat/
    ├── voice/
    ├── avatar/
    ├── spending/
    ├── financial_health/
    ├── goals/
    ├── recommendations/
    ├── portfolio/
    ├── predictive/
    ├── fraud/
    ├── notifications/
    └── profile/
```

---

## Develop & Test

```bash
# Install dependencies
flutter pub get

# Static analysis
flutter analyze

# Run all 115 tests
flutter test

# With coverage
flutter test --coverage

# Regenerate freezed / json_serializable / riverpod code
dart run build_runner build --delete-conflicting-outputs
```

---

## Key dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management and dependency injection |
| `dio` | HTTP client with interceptors and retry |
| `flutter_secure_storage` | Encrypted token storage |
| `shared_preferences` | Settings persistence |
| `dartz` | Functional `Either` error handling |
| `freezed` | Immutable data classes with `copyWith` |
| `json_serializable` | JSON serialization code generation |

---

## License

Proprietary — prepared for IDBI Innovate 2026. © 2026 SlimeAI Tech Pvt Ltd.
