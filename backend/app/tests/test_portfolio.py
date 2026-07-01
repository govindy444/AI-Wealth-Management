"""Tests for Portfolio Intelligence (pure engine + endpoints)."""
from fastapi.testclient import TestClient

from app.main import app
from app.models.portfolio import AssetClass, Holding
from app.services import portfolio_engine

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def _h(cls: AssetClass, invested: float, current: float) -> Holding:
    return Holding(id="x", user_id="u", name="x", asset_class=cls,
                   invested=invested, current_value=current)


# ── pure engine ──────────────────────────────────────────────────
def test_engine_allocation_and_performance() -> None:
    m = portfolio_engine.compute([
        _h(AssetClass.equity, 100, 150),
        _h(AssetClass.debt, 100, 110),
    ])
    assert m.total_value == 260
    assert m.total_invested == 200
    assert m.total_gain == 60
    assert m.allocation[AssetClass.equity] == round(150 / 260 * 100, 1)


def test_engine_all_equity_is_high_risk_low_diversification() -> None:
    m = portfolio_engine.compute([_h(AssetClass.equity, 100, 100)])
    assert portfolio_engine.risk_label(m.risk_score) == "high"
    assert m.diversification_score == 0  # single holding → fully concentrated


def test_engine_cash_only_is_low_risk() -> None:
    m = portfolio_engine.compute([_h(AssetClass.cash, 100, 100)])
    assert portfolio_engine.risk_label(m.risk_score) == "low"


# ── endpoints ────────────────────────────────────────────────────
def test_portfolio_requires_auth() -> None:
    assert client.get("/api/v1/portfolio/summary").status_code == 401


def test_summary_has_allocation_risk_and_insight() -> None:
    body = client.get("/api/v1/portfolio/summary", headers=_auth_headers()).json()
    assert body["total_value"] > 0
    assert 0 <= body["risk_score"] <= 100
    assert body["risk_label"] in ("low", "moderate", "high")

    total_pct = sum(s["percentage"] for s in body["allocation"])
    assert abs(total_pct - 100) < 0.5
    assert body["top_holdings"]
    assert body["insight"]["summary"]


def test_holdings_report_gains() -> None:
    holdings = client.get("/api/v1/portfolio/holdings", headers=_auth_headers()).json()
    assert len(holdings) >= 5
    bluechip = next(h for h in holdings if "Bluechip" in h["name"])
    assert bluechip["gain"] == bluechip["current_value"] - bluechip["invested"]
    assert bluechip["asset_class"] == "equity"
