# IDBI Wealth AI — Backend

Cloud-native FastAPI backend powering the AI Wealth SDK: authentication, banking APIs,
AI orchestration with a provider-agnostic LLM layer, RAG over IDBI product knowledge,
and production-grade security and observability.

---

## Stack

| Layer | Technology |
|---|---|
| Web framework | FastAPI 0.115 + Uvicorn (ASGI) |
| Validation | Pydantic v2 + pydantic-settings |
| Database | SQLAlchemy 2.0 (async) · SQLite (sandbox) · PostgreSQL + asyncpg (prod) |
| Migrations | Alembic |
| Auth | python-jose (JWT) · passlib + bcrypt |
| AI / LLM | Provider-agnostic: Anthropic SDK · OpenAI-compatible HTTP · NullLLM fallback |
| RAG | Custom: blake2 embedder + cosine vector store · Qdrant seam |
| Logging | structlog (JSON in prod, console in debug) |
| Metrics | In-process Prometheus exposition |
| Testing | pytest + pytest-cov (89% coverage) · ruff (lint) |

---

## Layout

```
backend/
├── app/
│   ├── main.py              # App factory, middleware stack, router mount
│   ├── core/
│   │   ├── config.py        # All settings (env vars / .env file)
│   │   ├── security.py      # JWT + password hashing
│   │   ├── security_middleware.py   # Security headers + rate limiter
│   │   ├── security_audit.py        # Production config validator
│   │   ├── login_throttle.py        # Brute-force protection
│   │   ├── metrics.py               # Prometheus metrics registry
│   │   ├── observability.py         # Request correlation + access log
│   │   ├── exceptions.py    # Error envelope + handlers
│   │   ├── dependencies.py  # FastAPI auth dependencies
│   │   └── logging.py       # structlog setup
│   ├── api/v1/              # Versioned routers (one file per domain)
│   ├── models/              # Domain dataclasses
│   ├── schemas/             # Pydantic request / response schemas
│   ├── repositories/        # Data access (in-memory + SQLAlchemy)
│   ├── services/            # Business logic
│   ├── ai/                  # LLM client, providers, orchestrator, RAG responder
│   ├── rag/                 # Embedder, vector store, chunker, knowledge base, retriever
│   ├── db/                  # SQLAlchemy base, session, seed
│   └── tests/               # 134 integration + unit tests
├── alembic/                 # DB migration scripts
├── requirements.txt
├── pyproject.toml           # pytest + coverage + ruff config
└── .env.example             # Copy to .env and fill in secrets
```

---

## Setup

### 1. Create and activate a virtual environment

```bash
cd backend
python -m venv .venv

# Windows
.venv\Scripts\activate

# macOS / Linux
source .venv/bin/activate
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Start the server

No external services needed — runs on SQLite with deterministic AI fallbacks.

```bash
python -m uvicorn app.main:app --port 8099 --reload
```

- Swagger UI: https://wealth.govzen.tech/docs
- ReDoc: https://wealth.govzen.tech/redoc
- Readiness probe: https://wealth.govzen.tech/api/v1/ready
- Prometheus metrics: https://wealth.govzen.tech/api/v1/metrics

**Demo credentials:** `demo@idbi.example` / `Password@123`

---

## Environment Variables

Copy `.env.example` to `.env` to override defaults:

```bash
cp .env.example .env
```

Key settings:

| Variable | Default | Description |
|---|---|---|
| `ENVIRONMENT` | `sandbox` | `sandbox` · `staging` · `production` |
| `DATABASE_URL` | SQLite | Set to `postgresql+asyncpg://...` for Postgres |
| `LLM_PROVIDER` | `anthropic` | `anthropic` · `openai` · `groq` · `ollama` · `openai_compatible` |
| `LLM_API_KEY` | *(empty)* | Leave empty to use deterministic fallback (no AI key needed) |
| `LLM_MODEL` | `claude-opus-4-8` | Any model supported by the chosen provider |
| `LLM_BASE_URL` | *(empty)* | For local/custom OpenAI-compatible endpoints |

---

## Running Tests

```bash
# All tests
pytest

# With coverage report
pytest --cov --cov-report=term-missing

# Lint
ruff check .
```

Current status: **134 tests · 89.45% coverage · ruff clean**

---

## API Domains

| Prefix | Description |
|---|---|
| `/api/v1/auth` | Register, login, refresh, logout, current user |
| `/api/v1/banking` | Dashboard, account summary |
| `/api/v1/chat` | AI advisor conversations |
| `/api/v1/voice` | Voice turn (STT transcript → AI reply) |
| `/api/v1/avatar` | Avatar personas + spoken presentation |
| `/api/v1/spending` | Transactions, category summary, budgets |
| `/api/v1/financial-health` | 5-pillar health score |
| `/api/v1/goals` | Goal CRUD + SIP simulation |
| `/api/v1/recommendations` | Risk-profiled investment recommendations |
| `/api/v1/portfolio` | Holdings, allocation, diversification score |
| `/api/v1/predictive` | Cash-flow forecast, upcoming bills |
| `/api/v1/fraud` | Anomaly alerts + scam message checker |
| `/api/v1/notifications` | Priority notification feed |
| `/api/v1/profile` | User profile + preferences |
| `/api/v1/ai` | LLM provider status |
| `/api/v1/rag` | Knowledge base search + info |
| `/api/v1/analytics` | Feature-usage event recording + summary |
| `/api/v1/metrics` | Prometheus metrics (text + JSON) |
| `/api/v1/ready` | Readiness probe (checks DB) |
| `/health` | Liveness probe |
