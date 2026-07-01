"""Investment domain models: products and risk profiles.

Lightweight dataclasses for the in-memory phase. Recommendations (allocation,
rationale) are computed by the recommendation engine, not stored here.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum


class RiskProfile(str, Enum):
    conservative = "conservative"
    moderate = "moderate"
    aggressive = "aggressive"


class RiskLevel(str, Enum):
    low = "low"
    moderate = "moderate"
    high = "high"


class ProductType(str, Enum):
    index_fund = "index_fund"
    equity_fund = "equity_fund"
    elss = "elss"
    debt_fund = "debt_fund"
    hybrid_fund = "hybrid_fund"
    fixed_deposit = "fixed_deposit"
    gold = "gold"


@dataclass
class InvestmentProduct:
    id: str
    name: str
    type: ProductType
    risk_level: RiskLevel
    expected_return: float  # annual, decimal
    min_investment: float
    description: str
    tags: list[str] = field(default_factory=list)
