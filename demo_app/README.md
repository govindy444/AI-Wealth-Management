# IDBI Wealth AI — Demo Banking App

A premium Flutter (Material 3) banking app that serves as the **reference
integration** for the [AI Wealth SDK](../../packages/ai_wealth_sdk). It
demonstrates how any bank embeds the SDK and exercises every wealth advisory
capability across 14 screens.

---

## Prerequisites

- Flutter 3.32.8 or later (`flutter --version`)
- Backend server running on port 8099 — see [backend setup](../../backend/README.md)

---

## Run

```bash
cd apps/demo_app
flutter pub get

# Android emulator (backend auto-configured to 10.0.2.2:8099)
flutter run

# iOS Simulator or physical device
flutter run

# Web browser
flutter run -d chrome

# List connected devices
flutter devices
```

**Physical device**: open `lib/main.dart` and update `_apiBaseUrl()` to your
machine's LAN IP, e.g. `http://192.168.1.100:8099/api/v1`.

---

## Demo credentials

| Field | Value |
|---|---|
| Email | `demo@idbi.example` |
| Password | `Password@123` |

---

## Screen tour

| Screen | What it shows |
|---|---|
| Splash | IDBI Wealth AI branding and SDK boot |
| Login / Register | JWT authentication via the SDK's `AuthController` |
| Dashboard | Account balance, recent transactions, health score quick-view |
| AI Chat | RAG-grounded conversational advisor (IDBI products knowledge base) |
| Voice Assistant | Tap-to-speak; transcript sent to AI; reply spoken back |
| AI Avatar | Animated avatar in multiple Indic-language personas |
| Spending Analytics | Category breakdown, budget progress, transaction history |
| Financial Health | 5-pillar score: savings, debt, investment, insurance, emergency fund |
| Goal Planner | Create goals, run SIP / TVM simulations, track progress |
| Investment Recommendations | Risk-profiled suggestions with explainability breakdowns |
| Portfolio Intelligence | Holdings, asset allocation pie, diversification score |
| Predictive Banking | 6-month cash-flow forecast, upcoming bill alerts |
| Fraud Alerts | Anomaly detections + scam-message scanner |
| Notifications | Prioritised in-app notification feed |
| Profile & Settings | Risk tolerance, language preference, account details |

---

## How it integrates the SDK

`lib/main.dart` is intentionally minimal — the same 5 lines a real bank app needs:

```dart
final sdk = WealthSdk.initialize(
  WealthSdkConfig(apiBaseUrl: _apiBaseUrl(), tenantId: 'idbi-demo'),
);
runApp(ProviderScope(overrides: sdk.overrides, child: const DemoApp()));
```

All state management, networking, token refresh, and business logic live inside
the SDK. The demo app only provides navigation shells and themed UI containers.

---

## Analyze & Test

```bash
# Static analysis
flutter analyze

# Run all 31 widget + integration tests
flutter test
```

---

## License

Proprietary — prepared for IDBI Innovate 2026. © 2026 IDBI Wealth AI Team.
