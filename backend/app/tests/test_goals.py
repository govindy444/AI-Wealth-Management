"""Tests for the Goal Planner (pure math + endpoints)."""
from datetime import date

from fastapi.testclient import TestClient

from app.main import app
from app.services import goal_math

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


# ── pure math ────────────────────────────────────────────────────
def test_future_value_zero_rate_is_simple_sum() -> None:
    # 1000 present + 100/mo for 12 months at 0% = 1000 + 1200.
    assert goal_math.future_value(1000, 100, 0.0, 12) == 2200


def test_required_monthly_hits_target() -> None:
    target, present, rate, months = 500_000, 100_000, 0.10, 36
    pmt = goal_math.required_monthly(target, present, rate, months)
    projected = goal_math.future_value(present, pmt, rate, months)
    assert abs(projected - target) < 1.0  # the SIP reaches the target


def test_months_between_counts_whole_months() -> None:
    assert goal_math.months_between(date(2026, 1, 15), date(2026, 7, 15)) == 6
    assert goal_math.months_between(date(2026, 7, 1), date(2026, 1, 1)) == 0  # never negative


def test_add_months_clamps_day() -> None:
    assert goal_math.add_months(date(2026, 1, 31), 1) == date(2026, 2, 28)


# ── endpoints ────────────────────────────────────────────────────
def test_goals_require_auth() -> None:
    assert client.get("/api/v1/goals").status_code == 401


def test_list_seeded_goals_with_projections() -> None:
    goals = client.get("/api/v1/goals", headers=_auth_headers()).json()
    names = {g["name"] for g in goals}
    assert {"Emergency Fund", "Retirement Corpus"}.issubset(names)
    for g in goals:
        assert 0 <= g["progress_pct"] <= 100
        assert g["required_monthly"] >= 0
        assert "on_track" in g


def test_simulate_returns_required_sip_and_insight() -> None:
    resp = client.post(
        "/api/v1/goals/simulate",
        json={
            "target_amount": 1_000_000,
            "target_date": "2031-06-01",
            "current_amount": 100_000,
            "monthly_contribution": 5_000,
            "expected_return_rate": 0.10,
        },
        headers=_auth_headers(),
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["required_monthly"] > 0
    assert body["projected_value"] is not None
    assert isinstance(body["on_track"], bool)
    assert body["insight"]["summary"]


def test_create_update_delete_goal_lifecycle() -> None:
    headers = _auth_headers()
    created = client.post(
        "/api/v1/goals",
        json={
            "name": "New Bike",
            "target_amount": 150_000,
            "target_date": "2027-06-01",
            "current_amount": 20_000,
            "monthly_contribution": 5_000,
            "category": "car",
        },
        headers=headers,
    )
    assert created.status_code == 201
    goal_id = created.json()["id"]

    updated = client.patch(
        f"/api/v1/goals/{goal_id}",
        json={"monthly_contribution": 9_000},
        headers=headers,
    ).json()
    assert updated["monthly_contribution"] == 9_000

    deleted = client.delete(f"/api/v1/goals/{goal_id}", headers=headers)
    assert deleted.status_code == 200
    assert client.get(f"/api/v1/goals/{goal_id}", headers=headers).status_code == 404
