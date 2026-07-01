"""Pydantic schemas for the Predictive Banking endpoints."""
from __future__ import annotations

from datetime import date

from pydantic import BaseModel

from app.models.prediction import PredictionSeverity, PredictionType
from app.schemas.banking import ExplanationOut


class PredictionOut(BaseModel):
    type: PredictionType
    title: str
    message: str
    predicted_date: date
    days_away: int
    severity: PredictionSeverity
    amount: float | None = None


class ForecastOut(BaseModel):
    as_of: date
    current_liquid_balance: float
    projected_month_end_balance: float
    predictions: list[PredictionOut]
    insight: ExplanationOut
