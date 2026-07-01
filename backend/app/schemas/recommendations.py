"""Pydantic schemas for the Investment Recommendation endpoints."""
from __future__ import annotations

from pydantic import BaseModel, Field

from app.models.investment import ProductType, RiskLevel, RiskProfile
from app.schemas.banking import ExplanationOut


class InvestmentProductOut(BaseModel):
    id: str
    name: str
    type: ProductType
    risk_level: RiskLevel
    expected_return: float
    min_investment: float
    description: str
    tags: list[str]


class RecommendationOut(BaseModel):
    product: InvestmentProductOut
    allocation_pct: float        # share of the portfolio, 0–100
    suggested_amount: float
    rationale: ExplanationOut    # why this product for this investor


class RecommendRequest(BaseModel):
    risk_profile: RiskProfile = RiskProfile.moderate
    amount: float = Field(default=100_000, gt=0)
    horizon_years: int = Field(default=5, ge=1, le=40)


class RecommendationSetOut(BaseModel):
    risk_profile: RiskProfile
    total_amount: float
    horizon_years: int
    blended_expected_return: float  # weighted annual return, decimal
    recommendations: list[RecommendationOut]
    insight: ExplanationOut
