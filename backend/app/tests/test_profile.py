"""Integration tests for the Profile & Settings endpoints."""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def test_profile_requires_auth() -> None:
    assert client.get("/api/v1/profile").status_code == 401


def test_get_profile_returns_kyc_and_preferences() -> None:
    body = client.get("/api/v1/profile", headers=_auth_headers()).json()
    assert body["email"] == "demo@idbi.example"
    assert body["kyc_status"] == "verified"
    assert body["risk_profile"] in ("conservative", "moderate", "aggressive")
    prefs = body["preferences"]
    assert "notifications_enabled" in prefs
    assert prefs["preferred_currency"] == "INR"
    assert "data_consent" in prefs


def test_patch_profile_updates_phone_and_risk() -> None:
    headers = _auth_headers()
    resp = client.patch(
        "/api/v1/profile",
        json={"phone": "+91 98765 43210", "risk_profile": "aggressive"},
        headers=headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["phone"] == "+91 98765 43210"
    assert body["risk_profile"] == "aggressive"
    # Persisted.
    again = client.get("/api/v1/profile", headers=headers).json()
    assert again["risk_profile"] == "aggressive"


def test_update_preferences_toggles_and_consent() -> None:
    headers = _auth_headers()
    resp = client.put(
        "/api/v1/profile/preferences",
        json={
            "marketing_enabled": True,
            "preferred_language": "hi",
            "preferred_currency": "usd",
            "data_consent": False,
        },
        headers=headers,
    )
    assert resp.status_code == 200
    prefs = resp.json()["preferences"]
    assert prefs["marketing_enabled"] is True
    assert prefs["preferred_language"] == "hi"
    assert prefs["preferred_currency"] == "USD"  # normalized to upper-case
    assert prefs["data_consent"] is False


def test_new_user_gets_a_default_profile() -> None:
    # A freshly-registered user has no seeded profile; one is created lazily.
    reg = client.post("/api/v1/auth/register", json={
        "email": "profile.new@idbi.example",
        "password": "Password@123",
        "full_name": "Profile New",
    })
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    body = client.get("/api/v1/profile", headers=headers).json()
    assert body["full_name"] == "Profile New"
    assert body["preferences"]["data_consent"] is True
