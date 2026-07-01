"""Pure financial-health scoring engine.

Deterministic, side-effect-free scoring so it's trivially testable and identical
across runs. The service layer feeds it aggregated numbers (from banking +
spending) and turns the scores into human-readable pillars. Module 21 can wrap an
LLM narrative around these numbers, but the *scores* stay rule-based and auditable.
"""
from __future__ import annotations

from dataclasses import dataclass

# Pillar keys.
SAVINGS = "savings"
DEBT = "debt"
EMERGENCY_FUND = "emergency_fund"
INVESTMENTS = "investments"
SPENDING = "spending"

# Relative weights of each pillar in the overall score (must sum to 1.0).
_WEIGHTS: dict[str, float] = {
    SAVINGS: 0.25,
    DEBT: 0.25,
    EMERGENCY_FUND: 0.20,
    INVESTMENTS: 0.15,
    SPENDING: 0.15,
}


@dataclass(frozen=True)
class HealthInputs:
    total_assets: float
    total_liabilities: float
    liquid_assets: float       # savings + current + deposits
    investment_assets: float   # mutual funds, etc.
    monthly_income: float
    monthly_spent: float
    spend_change_pct: float     # month-over-month, +/-%


@dataclass(frozen=True)
class HealthResult:
    overall: int               # 0–100
    pillar_scores: dict[str, int]


def _clamp(v: float) -> int:
    return int(round(max(0.0, min(100.0, v))))


def compute(inp: HealthInputs) -> HealthResult:
    # Savings rate: 20%+ of income saved → full marks.
    rate = (
        (inp.monthly_income - inp.monthly_spent) / inp.monthly_income
        if inp.monthly_income > 0
        else 0.0
    )
    savings = _clamp(rate / 0.20 * 100)

    # Debt-to-asset ratio: 0% → 100, ≥60% → 0.
    if inp.total_assets > 0:
        debt_ratio = inp.total_liabilities / inp.total_assets
    else:
        debt_ratio = 1.0 if inp.total_liabilities > 0 else 0.0
    debt = _clamp((1 - debt_ratio / 0.60) * 100)

    # Emergency fund: months of expenses covered by liquid assets; 6+ → 100.
    months = (inp.liquid_assets / inp.monthly_spent) if inp.monthly_spent > 0 else 6.0
    emergency = _clamp(months / 6.0 * 100)

    # Investment share of assets: 30%+ → 100.
    share = (inp.investment_assets / inp.total_assets) if inp.total_assets > 0 else 0.0
    investments = _clamp(share / 0.30 * 100)

    # Spending discipline: flat/down → 100, +30% or more → 0.
    spending = _clamp((1 - max(0.0, inp.spend_change_pct) / 30.0) * 100)

    scores = {
        SAVINGS: savings,
        DEBT: debt,
        EMERGENCY_FUND: emergency,
        INVESTMENTS: investments,
        SPENDING: spending,
    }
    overall = _clamp(sum(scores[k] * w for k, w in _WEIGHTS.items()))
    return HealthResult(overall=overall, pillar_scores=scores)


def status_for(score: int) -> str:
    if score >= 80:
        return "excellent"
    if score >= 60:
        return "good"
    if score >= 40:
        return "fair"
    return "poor"


def grade_for(score: int) -> str:
    if score >= 80:
        return "A"
    if score >= 65:
        return "B"
    if score >= 50:
        return "C"
    if score >= 35:
        return "D"
    return "E"
