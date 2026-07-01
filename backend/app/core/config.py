"""Application configuration via environment variables.

Uses pydantic-settings so every setting is validated and typed. Values are read
from the process environment and an optional `.env` file (see `.env.example`).
"""
from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── App ──────────────────────────────────────
    app_name: str = "IDBI Wealth AI Backend"
    api_v1_prefix: str = "/api/v1"
    environment: Literal["sandbox", "staging", "production"] = "sandbox"
    debug: bool = True

    # ── Security ─────────────────────────────────
    jwt_secret_key: str = Field(
        default="change-me-in-production-please-32chars-min",
        min_length=16,
    )
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    aes_encryption_key: str = Field(
        default="change-me-aes-key-32-bytes-long!!",
        description="32-byte key for AES-256 at-rest encryption of sensitive data.",
    )

    # ── CORS ─────────────────────────────────────
    cors_origins: list[str] = ["*"]

    # ── Security hardening ───────────────────────
    security_headers_enabled: bool = True
    hsts_enabled: bool = False             # enable behind TLS in production
    login_max_failures: int = 8            # lock login after N failures…
    login_lockout_seconds: int = 300       # …for this long (per email)
    rate_limit_enabled: bool = False       # global per-IP limiter (on in prod)
    rate_limit_requests: int = 120
    rate_limit_window_seconds: int = 60

    # ── Datastores ───────────────────────────────
    # SQLite by default → zero external deps in sandbox. Production sets
    # DATABASE_URL to Postgres, e.g. postgresql+asyncpg://user:pass@host/db
    database_url: str = "sqlite+aiosqlite:///./wealth_ai.db"
    redis_url: str = "redis://localhost:6379/0"
    qdrant_url: str = "http://localhost:6333"

    # ── RAG ──────────────────────────────────────
    # Local defaults (hashing embedder + in-memory store) → zero external deps.
    # Production: embedding_provider=openai + vector_store=qdrant.
    embedding_provider: str = "hashing"       # hashing | openai
    embedding_model: str = ""
    embedding_api_key: str = ""
    embedding_base_url: str = ""
    vector_store: str = "memory"              # memory | qdrant
    qdrant_collection: str = "idbi_wealth_kb"

    # ── AI providers ─────────────────────────────
    # Provider-agnostic. "anthropic" (default, claude-opus-4-8) or any
    # OpenAI-compatible endpoint ("openai", "groq", "together", "openrouter",
    # "ollama", "openai_compatible"). With no API key the LLM is disabled and the
    # deterministic rule-based engines are used — so the app runs with zero config.
    llm_provider: str = "anthropic"
    llm_model: str = "claude-opus-4-8"
    llm_api_key: str = ""
    llm_base_url: str = ""          # for OpenAI-compatible / local servers
    llm_max_tokens: int = 1024
    llm_temperature: float = 0.4


@lru_cache
def get_settings() -> Settings:
    """Return a cached singleton Settings instance."""
    return Settings()
