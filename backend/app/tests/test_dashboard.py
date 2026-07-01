"""Integration tests for the banking dashboard endpoint."""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def test_dashboard_requires_auth() -> None:
    assert client.get("/api/v1/banking/dashboard").status_code == 401


def test_dashboard_returns_accounts_and_net_worth() -> None:
    resp = client.get("/api/v1/banking/dashboard", headers=_auth_headers())
    assert resp.status_code == 200
    body = resp.json()

    assert body["full_name"] == "Demo User"
    assert body["currency"] == "INR"
    assert len(body["accounts"]) == 6

    # Net worth must equal assets minus liabilities, and the seeded data is
    # solidly positive (assets dominated by deposits + MF + savings).
    assert body["net_worth"] == round(
        body["total_assets"] - body["total_liabilities"], 2
    )
    assert body["total_liabilities"] > 0
    assert body["net_worth"] < body["total_assets"]


def test_dashboard_flags_liability_accounts() -> None:
    body = client.get("/api/v1/banking/dashboard", headers=_auth_headers()).json()
    liabilities = [a for a in body["accounts"] if a["is_liability"]]
    types = {a["type"] for a in liabilities}
    assert types == {"credit_card", "loan"}


def test_dashboard_carries_explainable_insight() -> None:
    body = client.get("/api/v1/banking/dashboard", headers=_auth_headers()).json()
    insight = body["insight"]
    assert insight["summary"]
    assert isinstance(insight["reasons"], list) and insight["reasons"]
    assert 0.0 <= insight["confidence"] <= 1.0
