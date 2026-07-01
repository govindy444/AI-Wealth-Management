"""Pydantic schemas for the Portfolio Intelligence endpoints."""
from __future__ import annotations

from pydantic import BaseModel

from app.models.portfolio import AssetClass
from app.schemas.banking import ExplanationOut


class HoldingOut(BaseModel):
    id: str
    name: str
    asset_class: AssetClass
    invested: float
    current_value: float
    gain: float
    gain_pct: float


class AllocationSliceOut(BaseModel):
    asset_class: AssetClass
    percentage: float
    value: float


class PortfolioSummaryOut(BaseModel):
    total_value: float
    total_invested: float
    total_gain: float
    gain_pct: float
    risk_score: int          # 0–100
    risk_label: str          # low | moderate | high
    diversification_score: int  # 0–100
    allocation: list[AllocationSliceOut]
    top_holdings: list[HoldingOut]
    insight: ExplanationOut
