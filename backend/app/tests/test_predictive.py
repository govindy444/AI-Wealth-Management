"""Tests for Predictive Banking (pure engine + endpoint)."""
from datetime import date

from fastapi.testclient import TestClient

from app.main import app
from app.models.prediction import PredictionType, RecurringItem
from app.models.spending import SpendCategory, Transaction, TransactionDirection
from app.services import prediction_engine

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def _txn(merchant: str, amount: float, direction, day: int, year: int, month: int):
    return Transaction(
        id=f"{merchant}{year}{month}", user_id="u",
        date=date(year, month, day), merchant=merchant, amount=amount,
        direction=direction, category=SpendCategory.other,
    )


# ── pure engine ──────────────────────────────────────────────────
def test_detect_recurring_needs_two_months() -> None:
    txns = [
        _txn("Netflix", 649, TransactionDirection.debit, 3, 2026, 4),
        _txn("Netflix", 649, TransactionDirection.debit, 3, 2026, 5),
        _txn("OneOff", 999, TransactionDirection.debit, 10, 2026, 5),
    ]
    items = prediction_engine.detect_recurring(txns)
    labels = {i.label for i in items}
    assert "Netflix" in labels
    assert "OneOff" not in labels  # only one month


def test_low_balance_warns_when_debits_exceed_buffer() -> None:
    today = date(2026, 6, 1)
    recurring = [
        RecurringItem("Salary", 100000, TransactionDirection.credit, 28, SpendCategory.income),
        RecurringItem("Rent", 90000, TransactionDirection.debit, 5, SpendCategory.rent),
    ]
    preds = prediction_engine.build_predictions(50000, recurring, today, threshold=25000)
    types = {p.type for p in preds}
    assert PredictionType.low_balance in types  # 50k - 90k rent dips below 25k
    assert PredictionType.salary_credit in types


def test_month_end_projection_adds_income_subtracts_bills() -> None:
    today = date(2026, 6, 1)
    recurring = [
        RecurringItem("Salary", 100000, TransactionDirection.credit, 10, SpendCategory.income),
        RecurringItem("Rent", 30000, TransactionDirection.debit, 12, SpendCategory.rent),
    ]
    projected = prediction_engine.project_month_end_balance(20000, recurring, today)
    assert projected == 90000  # 20000 + 100000 - 30000


# ── endpoint ─────────────────────────────────────────────────────
def test_forecast_requires_auth() -> None:
    assert client.get("/api/v1/predictive/forecast").status_code == 401


def test_forecast_returns_predictions_and_insight() -> None:
    body = client.get("/api/v1/predictive/forecast", headers=_auth_headers()).json()
    assert body["current_liquid_balance"] > 0
    assert body["predictions"]
    types = {p["type"] for p in body["predictions"]}
    # Seeded salary + home-loan EMI + a tax reminder should all surface.
    assert "salary_credit" in types
    assert "emi_due" in types
    assert "tax_reminder" in types
    for p in body["predictions"]:
        assert p["severity"] in ("info", "warning", "critical")
    assert body["insight"]["summary"]
