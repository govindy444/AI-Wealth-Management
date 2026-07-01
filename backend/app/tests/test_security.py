"""Tests for Module 23 security hardening: headers, login throttle, rate
limiter, and the production config audit."""
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.core.config import Settings
from app.core.login_throttle import LoginThrottler
from app.core.security_audit import audit_security, enforce_security
from app.core.security_middleware import RateLimitMiddleware, SecurityHeadersMiddleware
from app.main import app

client = TestClient(app)


# ── Security headers ─────────────────────────────────
def test_security_headers_present_on_responses() -> None:
    resp = client.get("/")
    assert resp.headers["X-Content-Type-Options"] == "nosniff"
    assert resp.headers["X-Frame-Options"] == "DENY"
    assert resp.headers["Referrer-Policy"] == "no-referrer"
    assert "Content-Security-Policy" in resp.headers


def test_docs_exempt_from_restrictive_csp() -> None:
    # Swagger UI loads external assets; a 'none' CSP would break it.
    resp = client.get("/docs")
    assert "Content-Security-Policy" not in resp.headers


# ── Login throttle (unit, isolated state) ────────────
def test_login_throttle_locks_after_max_failures() -> None:
    throttler = LoginThrottler(max_failures=3, lockout_seconds=300)
    user = "throwaway@example.com"
    assert not throttler.is_locked(user)
    for _ in range(3):
        throttler.record_failure(user)
    assert throttler.is_locked(user)


def test_login_throttle_resets_on_success() -> None:
    throttler = LoginThrottler(max_failures=2, lockout_seconds=300)
    user = "throwaway2@example.com"
    throttler.record_failure(user)
    throttler.record_failure(user)
    assert throttler.is_locked(user)
    throttler.reset(user)
    assert not throttler.is_locked(user)


# ── Rate limiter (isolated app with a tiny limit) ────
def test_rate_limiter_returns_429_when_exceeded() -> None:
    mini = FastAPI()
    mini.add_middleware(RateLimitMiddleware, limit=2, window_seconds=60)

    @mini.get("/ping")
    async def ping() -> dict[str, str]:
        return {"ok": "1"}

    local = TestClient(mini)
    assert local.get("/ping").status_code == 200
    assert local.get("/ping").status_code == 200
    blocked = local.get("/ping")
    assert blocked.status_code == 429
    assert blocked.json()["error"]["code"] == "rate_limited"
    assert "Retry-After" in blocked.headers


def test_headers_middleware_sets_hsts_when_enabled() -> None:
    mini = FastAPI()
    mini.add_middleware(SecurityHeadersMiddleware, hsts=True)

    @mini.get("/x")
    async def x() -> dict[str, str]:
        return {"ok": "1"}

    resp = TestClient(mini).get("/x")
    assert "Strict-Transport-Security" in resp.headers


# ── Production config audit ──────────────────────────
def test_audit_flags_default_secrets() -> None:
    issues = audit_security(Settings())
    joined = " ".join(issues)
    assert "JWT_SECRET_KEY" in joined
    assert "AES_ENCRYPTION_KEY" in joined
    assert "CORS" in joined


def test_enforce_raises_in_production_with_insecure_defaults() -> None:
    insecure = Settings(environment="production")
    try:
        enforce_security(insecure)
        raised = False
    except RuntimeError:
        raised = True
    assert raised


def test_enforce_passes_with_hardened_production_config() -> None:
    secure = Settings(
        environment="production",
        jwt_secret_key="a-real-strong-secret-key-value-here",
        aes_encryption_key="another-32-byte-real-key-value!!",
        cors_origins=["https://wealth.idbi.example"],
        debug=False,
    )
    enforce_security(secure)  # should not raise
