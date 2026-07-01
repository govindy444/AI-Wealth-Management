"""Integration tests for the authentication endpoints."""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def test_login_success_returns_tokens_and_user() -> None:
    resp = client.post("/api/v1/auth/login", json=DEMO)
    assert resp.status_code == 200
    body = resp.json()
    assert body["token_type"] == "bearer"
    assert body["access_token"] and body["refresh_token"]
    assert body["user"]["email"] == DEMO["email"]
    assert "customer" in body["user"]["roles"]


def test_login_wrong_password_unauthorized() -> None:
    resp = client.post(
        "/api/v1/auth/login", json={"email": DEMO["email"], "password": "wrong-pass"}
    )
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "unauthorized"


def test_me_requires_auth() -> None:
    assert client.get("/api/v1/auth/me").status_code == 401


def test_login_then_me() -> None:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    resp = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    assert resp.status_code == 200
    assert resp.json()["email"] == DEMO["email"]


def test_refresh_rotates_access_token() -> None:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    resp = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]}
    )
    assert resp.status_code == 200
    assert resp.json()["access_token"]


def test_refresh_rejects_access_token_as_refresh() -> None:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    resp = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": tokens["access_token"]}
    )
    assert resp.status_code == 401


def test_register_new_user_and_conflict() -> None:
    payload = {
        "email": "new.user@idbi.example",
        "password": "Password@123",
        "full_name": "New User",
    }
    first = client.post("/api/v1/auth/register", json=payload)
    assert first.status_code == 201
    again = client.post("/api/v1/auth/register", json=payload)
    assert again.status_code == 409
    assert again.json()["error"]["code"] == "conflict"
