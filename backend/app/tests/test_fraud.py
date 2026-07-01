"""Tests for Fraud Detection (pure engine + endpoints)."""
from datetime import date

from fastapi.testclient import TestClient

from app.main import app
from app.models.fraud import FraudAlertType, FraudRiskLevel
from app.models.spending import SpendCategory, Transaction, TransactionDirection
from app.services import fraud_engine

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def _txn(merchant: str, amount: float, day: int):
    return Transaction(
        id=f"{merchant}{day}", user_id="u", date=date(2026, 6, day),
        merchant=merchant, amount=amount,
        direction=TransactionDirection.debit, category=SpendCategory.other,
    )


# ── pure engine: anomalies ───────────────────────────────────────
def test_detects_unusually_large_transaction() -> None:
    txns = [_txn("A", 500, 1), _txn("B", 600, 2), _txn("Big", 50000, 3)]
    alerts = fraud_engine.detect_anomalies(txns)
    assert any(a.type == FraudAlertType.unusual_amount and a.merchant == "Big"
               for a in alerts)


def test_detects_duplicate_charge() -> None:
    txns = [_txn("Shop", 2999, 1), _txn("Shop", 2999, 2)]
    alerts = fraud_engine.detect_anomalies(txns)
    dup = [a for a in alerts if a.type == FraudAlertType.duplicate_charge]
    assert len(dup) == 1
    assert dup[0].risk_level == FraudRiskLevel.medium


def test_no_alerts_for_normal_activity() -> None:
    txns = [_txn("A", 500, 1), _txn("B", 600, 2), _txn("C", 700, 3)]
    assert fraud_engine.detect_anomalies(txns) == []


# ── pure engine: phishing ────────────────────────────────────────
def test_phishing_message_is_high_risk() -> None:
    level, score, reasons = fraud_engine.check_message(
        "URGENT: Your account is blocked. Share your OTP and click http://bit.ly/x to verify."
    )
    assert level == FraudRiskLevel.high
    assert score >= 50
    assert len(reasons) >= 3


def test_benign_message_is_low_risk() -> None:
    level, score, reasons = fraud_engine.check_message("Hi, are we still meeting at 5pm?")
    assert level == FraudRiskLevel.low
    assert score == 0


# ── endpoints ────────────────────────────────────────────────────
def test_alerts_require_auth() -> None:
    assert client.get("/api/v1/fraud/alerts").status_code == 401


def test_alerts_endpoint_flags_seeded_anomalies() -> None:
    body = client.get("/api/v1/fraud/alerts", headers=_auth_headers()).json()
    assert body["scanned_count"] >= 6
    types = {a["type"] for a in body["alerts"]}
    assert "unusual_amount" in types      # QuickElectronics 48,999
    assert "duplicate_charge" in types    # PayFast x2
    assert body["insight"]["summary"]


def test_check_message_endpoint() -> None:
    resp = client.post(
        "/api/v1/fraud/check-message",
        json={"text": "Claim your lottery prize now! Share your PIN to receive cashback."},
        headers=_auth_headers(),
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["risk_level"] == "high"
    assert body["is_safe"] is False
    assert body["explanation"]["reasons"]
