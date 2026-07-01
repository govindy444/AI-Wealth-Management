"""Pure fraud-detection logic.

Two deterministic detectors:
  • `detect_anomalies` — flags transactions that look unusual (very large vs the
    typical spend, or duplicate charges).
  • `check_message` — scores an SMS/email for scam/phishing indicators.

Both are side-effect-free and explainable. Module 21 can replace them with ML /
LLM classifiers behind the same signatures.
"""
from __future__ import annotations

import re
import statistics
from collections import defaultdict

from app.models.fraud import FraudAlert, FraudAlertType, FraudRiskLevel
from app.models.spending import Transaction

# A transaction this many times the median spend is "unusual".
_UNUSUAL_FACTOR = 5.0
_UNUSUAL_ABS_FLOOR = 20_000.0


def detect_anomalies(transactions: list[Transaction]) -> list[FraudAlert]:
    alerts: list[FraudAlert] = []
    if not transactions:
        return alerts

    amounts = [t.amount for t in transactions]
    median = statistics.median(amounts)
    threshold = max(_UNUSUAL_ABS_FLOOR, median * _UNUSUAL_FACTOR)

    # Unusually large transactions.
    for t in transactions:
        if t.amount >= threshold:
            alerts.append(FraudAlert(
                id=f"alert_amt_{t.id}",
                type=FraudAlertType.unusual_amount,
                risk_level=FraudRiskLevel.high,
                merchant=t.merchant,
                amount=t.amount,
                date=t.date,
                reason=(
                    f"₹{t.amount:,.0f} at {t.merchant} is far above your typical "
                    f"spend (median ₹{median:,.0f}). Confirm you made this purchase."
                ),
            ))

    # Duplicate charges: same merchant + amount appearing more than once close together.
    groups: dict[tuple[str, float], list[Transaction]] = defaultdict(list)
    for t in transactions:
        groups[(t.merchant, t.amount)].append(t)
    for (merchant, amount), group in groups.items():
        if len(group) < 2:
            continue
        group.sort(key=lambda t: t.date)
        if (group[-1].date - group[0].date).days <= 3:
            alerts.append(FraudAlert(
                id=f"alert_dup_{group[0].id}",
                type=FraudAlertType.duplicate_charge,
                risk_level=FraudRiskLevel.medium,
                merchant=merchant,
                amount=amount,
                date=group[-1].date,
                reason=(
                    f"{len(group)} identical charges of ₹{amount:,.0f} at {merchant} "
                    "within a few days — possible duplicate billing."
                ),
            ))

    alerts.sort(key=lambda a: (a.risk_level != FraudRiskLevel.high, a.date), reverse=False)
    return alerts


# ── phishing / scam message checker ──────────────────────────────
# keyword (regex) → (points, human reason)
_INDICATORS: list[tuple[str, int, str]] = [
    (r"https?://|bit\.ly|tinyurl|\bclick\b", 25, "Contains a link to click."),
    (r"\botp\b|one[\s-]?time password", 30, "Asks for an OTP — banks never ask for this."),
    (r"\b(pin|cvv|password|card number)\b", 35, "Requests secret credentials."),
    (r"urgent|immediately|within \d+ (hours|minutes)|act now", 20, "Creates false urgency."),
    (r"account (has been )?(blocked|suspended|frozen)", 25, "Threatens account suspension."),
    (r"kyc|re-?verify|update your details", 20, "Fake KYC / verification request."),
    (r"won|lottery|prize|reward|cashback", 20, "Too-good-to-be-true reward."),
    (r"refund|claim", 10, "Unsolicited refund/claim bait."),
]


def check_message(text: str) -> tuple[FraudRiskLevel, int, list[str]]:
    lowered = text.lower()
    score = 0
    reasons: list[str] = []
    for pattern, points, reason in _INDICATORS:
        if re.search(pattern, lowered):
            score += points
            reasons.append(reason)
    score = min(score, 100)

    if score >= 50:
        level = FraudRiskLevel.high
    elif score >= 20:
        level = FraudRiskLevel.medium
    else:
        level = FraudRiskLevel.low

    if not reasons:
        reasons.append("No common scam indicators detected.")
    return level, score, reasons
