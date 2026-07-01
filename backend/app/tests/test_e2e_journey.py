"""End-to-end customer journey across modules.

Unlike the per-module integration tests, this walks a single realistic session
through the *integrated* stack — auth → dashboard → spending → goals →
recommendations → advisor chat → analytics → observability — proving the slices
compose correctly and that cross-cutting middleware (auth, correlation IDs,
metrics, security headers) is exercised on a real multi-endpoint flow.
"""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def test_new_customer_can_register() -> None:
    # Fresh user proves the auth write path end-to-end (idempotent on re-run:
    # a repeat registration yields 409, which is still a healthy signal).
    payload = {
        "email": "journey.user@idbi.example",
        "password": "Password@123",
        "full_name": "Journey User",
    }
    resp = client.post("/api/v1/auth/register", json=payload)
    assert resp.status_code in (201, 409)


def test_full_session_journey() -> None:
    # 1) Authenticate.
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    headers = {"Authorization": f"Bearer {tokens['access_token']}"}
    assert tokens["access_token"]

    # Every authed response should carry the cross-cutting headers.
    me = client.get("/api/v1/auth/me", headers=headers)
    assert me.status_code == 200
    assert me.json()["email"] == DEMO["email"]
    assert me.headers.get("X-Request-ID")
    assert me.headers["X-Content-Type-Options"] == "nosniff"

    # 2) Money overview.
    dashboard = client.get("/api/v1/banking/dashboard", headers=headers)
    assert dashboard.status_code == 200

    spending = client.get("/api/v1/spending/summary", headers=headers)
    assert spending.status_code == 200

    health = client.get("/api/v1/financial-health/score", headers=headers)
    assert health.status_code == 200
    assert 0 <= health.json()["score"] <= 100

    # 3) Planning + advice.
    goals = client.get("/api/v1/goals", headers=headers)
    assert goals.status_code == 200

    recos = client.post(
        "/api/v1/recommendations",
        json={"risk_profile": "moderate", "amount": 100000, "horizon_years": 5},
        headers=headers,
    )
    assert recos.status_code == 200

    # 4) Ask the AI advisor (deterministic fallback offline → always replies).
    chat = client.post(
        "/api/v1/chat/messages",
        json={"message": "How should I invest my savings?"},
        headers=headers,
    )
    assert chat.status_code == 200
    assert chat.json()["message"]["role"] == "assistant"

    # 5) The app reports feature usage; the business reads it back.
    for name, feature in [
        ("viewed_dashboard", "dashboard"),
        ("asked_advisor", "chat"),
    ]:
        ev = client.post(
            "/api/v1/analytics/events",
            json={"name": name, "feature": feature},
            headers=headers,
        )
        assert ev.status_code == 201

    summary = client.get("/api/v1/analytics/summary", headers=headers).json()
    assert summary["total_events"] >= 2

    # 6) Observability reflects the traffic this journey generated.
    metrics = client.get("/api/v1/metrics")
    assert metrics.status_code == 200
    assert "http_requests_total{" in metrics.text


def test_unauthenticated_requests_are_rejected_across_modules() -> None:
    # A representative protected endpoint from each domain must require auth.
    for path in (
        "/api/v1/banking/dashboard",
        "/api/v1/spending/summary",
        "/api/v1/goals",
        "/api/v1/portfolio/summary",
        "/api/v1/analytics/summary",
    ):
        assert client.get(path).status_code == 401, path
