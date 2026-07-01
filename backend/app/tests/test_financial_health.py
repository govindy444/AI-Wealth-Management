"""Tests for the Financial Health Engine (pure engine + endpoint)."""
from fastapi.testclient import TestClient

from app.main import app
from app.services import health_engine as engine
from app.services.health_engine import HealthInputs

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


# ── pure engine ──────────────────────────────────────────────────
def test_engine_perfect_profile_scores_high() -> None:
    result = engine.compute(HealthInputs(
        total_assets=1_000_000,
        total_liabilities=0,
        liquid_assets=600_000,      # 6 months of expenses
        investment_assets=400_000,  # 40% invested
        monthly_income=100_000,
        monthly_spent=80_000,       # not relevant to emergency since 600k/100k... uses spent
        spend_change_pct=-5,
    ))
    assert result.overall >= 70
    assert engine.grade_for(result.overall) in ("A", "B")


def test_engine_debt_heavy_profile_scores_low() -> None:
    result = engine.compute(HealthInputs(
        total_assets=100_000,
        total_liabilities=90_000,   # 90% debt ratio
        liquid_assets=10_000,
        investment_assets=0,
        monthly_income=50_000,
        monthly_spent=49_000,       # ~2% savings
        spend_change_pct=40,        # spending spiking
    ))
    assert result.overall <= 35
    assert result.pillar_scores[engine.DEBT] == 0
    assert result.pillar_scores[engine.SPENDING] == 0


def test_engine_scores_are_bounded() -> None:
    result = engine.compute(HealthInputs(
        total_assets=0, total_liabilities=0, liquid_assets=0,
        investment_assets=0, monthly_income=0, monthly_spent=0, spend_change_pct=0,
    ))
    for v in result.pillar_scores.values():
        assert 0 <= v <= 100
    assert 0 <= result.overall <= 100


# ── endpoint ─────────────────────────────────────────────────────
def test_score_requires_auth() -> None:
    assert client.get("/api/v1/financial-health/score").status_code == 401


def test_score_returns_pillars_and_insight() -> None:
    body = client.get("/api/v1/financial-health/score", headers=_auth_headers()).json()
    assert 0 <= body["score"] <= 100
    assert body["grade"] in ("A", "B", "C", "D", "E")
    assert body["status"] in ("poor", "fair", "good", "excellent")

    keys = {p["key"] for p in body["pillars"]}
    assert keys == {"savings", "debt", "emergency_fund", "investments", "spending"}
    for p in body["pillars"]:
        assert p["detail"] and p["recommendation"]
        assert 0 <= p["score"] <= 100

    assert body["insight"]["summary"]
    assert body["insight"]["risks"]  # names the weakest pillar


def test_system_health_check_still_works() -> None:
    # The financial-health route must not shadow the system liveness check.
    assert client.get("/api/v1/health").status_code == 200
