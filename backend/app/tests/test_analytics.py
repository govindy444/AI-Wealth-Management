"""Tests for the Module 24 product-analytics endpoints."""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def test_record_event_requires_auth() -> None:
    resp = client.post(
        "/api/v1/analytics/events", json={"name": "x", "feature": "y"}
    )
    assert resp.status_code == 401


def test_record_event_and_summary() -> None:
    headers = _auth()
    for name, feature in [
        ("viewed_dashboard", "Dashboard"),
        ("asked_advisor", "chat"),
        ("asked_advisor", "chat"),
    ]:
        resp = client.post(
            "/api/v1/analytics/events",
            json={"name": name, "feature": feature, "properties": {"k": 1}},
            headers=headers,
        )
        assert resp.status_code == 201
        assert resp.json()["id"].startswith("evt_")
        # feature is normalized to lowercase
        assert resp.json()["feature"] == feature.lower()

    summary = client.get("/api/v1/analytics/summary", headers=headers).json()
    assert summary["total_events"] >= 3
    features = {f["feature"]: f["count"] for f in summary["by_feature"]}
    assert features.get("chat", 0) >= 2
    assert features.get("dashboard", 0) >= 1
    top = {e["name"]: e["count"] for e in summary["top_events"]}
    assert top.get("asked_advisor", 0) >= 2
    assert summary["last_event_at"] is not None


def test_event_validation_rejects_blank_name() -> None:
    resp = client.post(
        "/api/v1/analytics/events",
        json={"name": "", "feature": "dashboard"},
        headers=_auth(),
    )
    assert resp.status_code == 422
