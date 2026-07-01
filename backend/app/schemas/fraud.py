"""Pydantic schemas for the Fraud Detection endpoints."""
from __future__ import annotations

from datetime import date

from pydantic import BaseModel, Field

from app.models.fraud import FraudAlertType, FraudRiskLevel
from app.schemas.banking import ExplanationOut


class FraudAlertOut(BaseModel):
    id: str
    type: FraudAlertType
    risk_level: FraudRiskLevel
    merchant: str
    amount: float
    date: date
    reason: str


class FraudAlertsOut(BaseModel):
    scanned_count: int
    alerts: list[FraudAlertOut]
    insight: ExplanationOut


class CheckMessageRequest(BaseModel):
    text: str = Field(min_length=1, max_length=4000)


class CheckMessageResponse(BaseModel):
    risk_level: FraudRiskLevel
    score: int            # 0–100
    is_safe: bool
    explanation: ExplanationOut
