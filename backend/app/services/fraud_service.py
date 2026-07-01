"""Fraud Detection business logic.

Runs the pure fraud engine over recent activity to surface anomaly alerts, and
scores ad-hoc messages for scam/phishing risk. Both responses carry an
Explainable-AI envelope.
"""
from __future__ import annotations

from app.models.fraud import FraudAlert, FraudRiskLevel
from app.models.user import User
from app.repositories.fraud_repository import FraudRepository
from app.schemas.banking import ExplanationOut
from app.schemas.fraud import (
    CheckMessageResponse,
    FraudAlertOut,
    FraudAlertsOut,
)
from app.services import fraud_engine


class FraudService:
    def __init__(self, repo: FraudRepository) -> None:
        self._repo = repo

    async def alerts(self, user: User) -> FraudAlertsOut:
        txns = await self._repo.recent_transactions(user.id)
        alerts = fraud_engine.detect_anomalies(txns)
        return FraudAlertsOut(
            scanned_count=len(txns),
            alerts=[self._to_alert_out(a) for a in alerts],
            insight=self._alerts_insight(alerts, len(txns)),
        )

    def check_message(self, text: str) -> CheckMessageResponse:
        level, score, reasons = fraud_engine.check_message(text)
        is_safe = level == FraudRiskLevel.low
        summary = {
            FraudRiskLevel.high: "This looks like a scam — do not respond or click anything.",
            FraudRiskLevel.medium: "This message is suspicious — treat it with caution.",
            FraudRiskLevel.low: "No obvious scam signals, but always stay alert.",
        }[level]
        return CheckMessageResponse(
            risk_level=level,
            score=score,
            is_safe=is_safe,
            explanation=ExplanationOut(
                summary=summary,
                reasons=reasons,
                risks=["Never share OTPs, PINs, or passwords — your bank will never ask."]
                if not is_safe else [],
                benefits=[],
                alternatives=["Report suspicious messages to your bank's official channel."]
                if not is_safe else [],
                citations=["Rule-based phishing indicators."],
                confidence=0.7,
            ),
        )

    @staticmethod
    def _to_alert_out(a: FraudAlert) -> FraudAlertOut:
        return FraudAlertOut(
            id=a.id,
            type=a.type,
            risk_level=a.risk_level,
            merchant=a.merchant,
            amount=a.amount,
            date=a.date,
            reason=a.reason,
        )

    @staticmethod
    def _alerts_insight(alerts: list[FraudAlert], scanned: int) -> ExplanationOut:
        high = sum(1 for a in alerts if a.risk_level == FraudRiskLevel.high)
        if not alerts:
            summary = f"No anomalies in your last {scanned} transactions — all clear."
        else:
            summary = (
                f"{len(alerts)} alert(s) found in your last {scanned} transactions"
                + (f", including {high} high-risk." if high else ".")
            )
        return ExplanationOut(
            summary=summary,
            reasons=[a.reason for a in alerts[:3]],
            risks=["Review flagged transactions and report anything you don't recognise."]
            if alerts else [],
            benefits=[],
            alternatives=["Freeze your card instantly from the app if a charge is fraudulent."]
            if alerts else [],
            citations=["Rule-based anomaly detection on recent activity."],
            confidence=0.75,
        )
