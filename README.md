# IDBI Wealth AI SDK

> **Plug-and-Play AI Wealth Advisor for Digital Banking.**

A modular, production-ready **AI Wealth SDK** that any bank can embed into its existing
mobile application with 5 lines of Dart — bundled with a polished Flutter demo banking
app and a cloud-native FastAPI AI backend.

Built for **IDBI Innovate 2026**.

---

## Repository Layout

```
idbi-wealth-ai/
├── apps/
│   └── demo_app/            # Flutter demo banking app (Material 3)
├── packages/
│   └── ai_wealth_sdk/       # Embeddable Flutter SDK — the core product
├── backend/                 # FastAPI AI backend (auth, banking, AI, RAG)
├── docs/
│   └── architecture/
│       └── ARCHITECTURE.md  # Full system design
├── .github/
│   └── workflows/ci.yml     # GitHub 
├── CHANGELOG.md             # Per-module changelog
└── TESTING.md               # How to run all test suites
```

---

## The Three Deliverables

| # | Component | Tech | Role |
|---|-----------|------|------|
| 1 | **AI Wealth SDK** | Flutter / Dart | The reusable product banks embed into their app |
| 2 | **Demo Banking App** | Flutter (Material 3) | Reference integration showcasing every SDK feature |
| 3 | **AI Backend** | FastAPI + RAG + SQLAlchemy | Server-side AI orchestration, banking APIs, knowledge base |

---

## Architecture

```
┌──────────────────────────────┐
│   Flutter Demo Banking App   │   (or any host bank app)
└──────────────┬───────────────┘
               │  embeds
┌──────────────▼───────────────┐
│        AI Wealth SDK          │
│  Auth · Dashboard · Chat ·    │
│  Avatar · Voice · Spending ·  │
│  Health · Goals · Recos ·     │
│  Portfolio · Fraud · Notify   │
└──────────────┬───────────────┘
               │  HTTPS / JWT
┌──────────────▼───────────────┐
│        FastAPI AI Backend     │
│  AI Orchestrator · RAG ·      │
│  Recommendation Engine ·      │
│  Security · Observability     │
└──────────────┬───────────────┘
               │
   ┌───────────┼─────────────┐
   ▼           ▼             ▼
  LLM        Qdrant      PostgreSQL
(Anthropic / (vectors)  (system of record)
 OpenAI /
 Groq / Ollama
 or any endpoint)
```

The LLM layer is **provider-agnostic** — works with Anthropic Claude, OpenAI, Groq,
Ollama, or any OpenAI-compatible endpoint. With no API key configured, the app falls
back to deterministic rule-based engines so it runs fully offline.

---

## Quick Start

### Backend

```bash
cd backend

# Create virtual environment
python -m venv .venv

# Activate — Windows:
.venv\Scripts\activate
# Activate — macOS/Linux:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start the server (SQLite sandbox, no external services needed)
python -m uvicorn app.main:app --port 8099 --reload
```

Open **https://wealth.govzen.tech/docs** for the interactive Swagger UI.

Demo login: `demo@idbi.example` / `Password@123`

### Flutter SDK + Demo App

```bash
# Install SDK dependencies
cd packages/ai_wealth_sdk
flutter pub get

# Install and run the demo app
cd ../../apps/demo_app
flutter pub get
flutter run
```

On a physical device, update `_apiBaseUrl()` in `apps/demo_app/lib/main.dart` to your
machine's local IP.

---

## Features (20 AI modules)

| Category | Features |
|---|---|
| **AI & Conversational** | Chat Advisor (RAG-grounded) · Voice Assistant (STT→AI→TTS) · Animated AI Avatar · Provider-agnostic LLM · IDBI Knowledge Base (12 docs) |
| **Financial Intelligence** | Financial Health Score · Explainable Investment Recommendations · Portfolio Intelligence · Goal Planner (TVM/SIP) · Predictive Banking · Spending Analytics · Fraud Detection |
| **Platform** | Embeddable Flutter SDK · FastAPI Backend · Security Hardening · Analytics & Monitoring · Smart Notifications · Profile & Settings · Cross-Platform · CI/CD |

---

## Test Suites

| Package | Command | Tests | Coverage |
|---|---|---|---|
| Backend | `cd backend && pytest --cov` | 134 | 89% |
| SDK | `cd packages/ai_wealth_sdk && flutter test` | 115 | — |
| Demo app | `cd apps/demo_app && flutter test` | 31 | — |
| SDK example | `cd packages/ai_wealth_sdk/example && flutter test` | 6 | — |


---

## Optional: Enable a Real LLM

By default the backend uses a deterministic rule-based engine (no API key needed).
To enable an LLM, create `backend/.env`:

```env
LLM_PROVIDER=anthropic
LLM_MODEL=claude-opus-4-8
LLM_API_KEY=your-key-here
```

Supported providers: `anthropic` · `openai` · `groq` · `together` · `openrouter` ·
`ollama` · any OpenAI-compatible endpoint (set `LLM_BASE_URL`).

---

## License

Proprietary — prepared for IDBI Innovate 2026. © 2026 SlimeAI Tech Pvt Ltd.
"# AI-Wealth-Management" 
