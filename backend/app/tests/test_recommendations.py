"""Integration tests for the Investment Recommendation endpoints."""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def test_recommendations_require_auth() -> None:
    assert client.get("/api/v1/recommendations/products").status_code == 401


def test_product_catalog_lists_shelf() -> None:
    products = client.get(
        "/api/v1/recommendations/products", headers=_auth_headers()
    ).json()
    ids = {p["id"] for p in products}
    assert {"idbi_nifty_index", "idbi_fd", "idbi_gold_etf"}.issubset(ids)
    for p in products:
        assert p["expected_return"] > 0
        assert p["risk_level"] in ("low", "moderate", "high")


def test_recommendation_allocations_sum_to_100_with_amounts_and_rationale() -> None:
    resp = client.post(
        "/api/v1/recommendations",
        json={"risk_profile": "moderate", "amount": 200000, "horizon_years": 7},
        headers=_auth_headers(),
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["risk_profile"] == "moderate"

    total_pct = sum(r["allocation_pct"] for r in body["recommendations"])
    assert abs(total_pct - 100) < 0.01

    total_amount = sum(r["suggested_amount"] for r in body["recommendations"])
    assert abs(total_amount - 200000) < 1.0

    # Every recommendation carries an explainable rationale.
    for r in body["recommendations"]:
        assert r["rationale"]["summary"]
        assert r["rationale"]["risks"]
    assert body["insight"]["summary"]
    assert 0 < body["blended_expected_return"] < 0.2


def test_risk_profiles_shift_equity_exposure() -> None:
    headers = _auth_headers()

    def equity_pct(profile: str) -> float:
        body = client.post(
            "/api/v1/recommendations",
            json={"risk_profile": profile, "amount": 100000},
            headers=headers,
        ).json()
        equity_types = {"index_fund", "equity_fund", "elss"}
        return sum(
            r["allocation_pct"]
            for r in body["recommendations"]
            if r["product"]["type"] in equity_types
        )

    # More aggressive → more equity.
    assert equity_pct("aggressive") > equity_pct("moderate") > equity_pct("conservative")


def test_blended_return_rises_with_risk() -> None:
    headers = _auth_headers()

    def blended(profile: str) -> float:
        return client.post(
            "/api/v1/recommendations",
            json={"risk_profile": profile, "amount": 100000},
            headers=headers,
        ).json()["blended_expected_return"]

    assert blended("aggressive") > blended("conservative")
