"""Pydantic schemas for the Financial Health Engine endpoints."""
from __future__ import annotations

from pydantic import BaseModel

from app.schemas.banking import ExplanationOut


class HealthPillarOut(BaseModel):
    key: str
    label: str
    score: int          # 0–100
    status: str         # poor | fair | good | excellent
    detail: str         # plain-language explanation of the current figure
    recommendation: str  # the next action to improve this pillar


class FinancialHealthOut(BaseModel):
    score: int          # 0–100 overall
    grade: str          # A–E
    status: str         # poor | fair | good | excellent
    pillars: list[HealthPillarOut]
    insight: ExplanationOut
