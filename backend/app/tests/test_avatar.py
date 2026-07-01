"""Integration tests for the AI Avatar endpoints."""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def test_avatar_requires_auth() -> None:
    assert client.get("/api/v1/avatar/personas").status_code == 401


def test_list_personas() -> None:
    resp = client.get("/api/v1/avatar/personas", headers=_auth_headers())
    assert resp.status_code == 200
    personas = resp.json()
    ids = {p["id"] for p in personas}
    assert {"aanya", "vikram"}.issubset(ids)
    aanya = next(p for p in personas if p["id"] == "aanya")
    assert "hi" in aanya["languages"]


def test_present_text_segments_and_expression() -> None:
    resp = client.post(
        "/api/v1/avatar/present",
        json={"text": "Your net worth grew this month. Great job saving!"},
        headers=_auth_headers(),
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["expression"] == "happy"  # positive keywords
    assert len(body["segments"]) == 2  # two sentences
    assert body["total_duration_ms"] == sum(s["duration_ms"] for s in body["segments"])


def test_present_detects_concern() -> None:
    body = client.post(
        "/api/v1/avatar/present",
        json={"text": "Your credit card debt is high and rising."},
        headers=_auth_headers(),
    ).json()
    assert body["expression"] == "concerned"


def test_present_falls_back_to_localized_greeting() -> None:
    body = client.post(
        "/api/v1/avatar/present",
        json={"persona_id": "aanya", "language": "hi"},
        headers=_auth_headers(),
    ).json()
    assert body["language"] == "hi"
    assert "Aanya" in body["text"]  # name interpolated into Hindi greeting
    assert body["segments"]


def test_present_unsupported_language_falls_back_to_default() -> None:
    # Vikram does not speak Tamil → should fall back to his default (en).
    body = client.post(
        "/api/v1/avatar/present",
        json={"persona_id": "vikram", "language": "ta"},
        headers=_auth_headers(),
    ).json()
    assert body["language"] == "en"


def test_present_unknown_persona_is_404() -> None:
    resp = client.post(
        "/api/v1/avatar/present",
        json={"persona_id": "nobody", "text": "hi"},
        headers=_auth_headers(),
    )
    assert resp.status_code == 404
