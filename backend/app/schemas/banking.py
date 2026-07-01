"""Pydantic schemas for banking / dashboard endpoints."""
from __future__ import annotations

from pydantic import BaseModel, Field

from app.models.account import AccountType


class ExplanationOut(BaseModel):
    """Explainable-AI envelope attached to every AI insight/recommendation.

    Mirrors the SDK `Explanation` contract and ARCHITECTURE.md §5.
    """

    summary: str
    reasons: list[str] = Field(default_factory=list)
    risks: list[str] = Field(default_factory=list)
    benefits: list[str] = Field(default_factory=list)
    alternatives: list[str] = Field(default_factory=list)
    citations: list[str] = Field(default_factory=list)
    confidence: float = 0.0


class AccountOut(BaseModel):
    id: str
    name: str
    type: AccountType
    masked_number: str
    balance: float
    currency: str
    monthly_change: float
    is_liability: bool


class DashboardResponse(BaseModel):
    user_id: str
    full_name: str
    currency: str
    net_worth: float
    total_assets: float
    total_liabilities: float
    monthly_change: float
    accounts: list[AccountOut]
    insight: ExplanationOut
