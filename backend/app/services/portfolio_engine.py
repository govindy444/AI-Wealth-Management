"""Pure portfolio analytics.

Deterministic, side-effect-free computation of allocation, performance, a risk
score, and a diversification score from a set of holdings. Trivially testable; the
service layer adds narrative and rebalancing advice on top.
"""
from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass

from app.models.portfolio import AssetClass, Holding

# Each asset class's contribution to portfolio risk on a 0–100 scale.
_RISK_WEIGHT: dict[AssetClass, float] = {
    AssetClass.equity: 90,
    AssetClass.real_estate: 60,
    AssetClass.gold: 55,
    AssetClass.debt: 25,
    AssetClass.cash: 5,
}


@dataclass(frozen=True)
class PortfolioMetrics:
    total_value: float
    total_invested: float
    total_gain: float
    gain_pct: float
    allocation: dict[AssetClass, float]  # class → percent of current value
    risk_score: int                      # 0–100
    diversification_score: int           # 0–100


def compute(holdings: list[Holding]) -> PortfolioMetrics:
    total_value = sum(h.current_value for h in holdings)
    total_invested = sum(h.invested for h in holdings)
    gain = total_value - total_invested

    by_class: dict[AssetClass, float] = defaultdict(float)
    for h in holdings:
        by_class[h.asset_class] += h.current_value

    allocation = {
        cls: round(val / total_value * 100, 1) if total_value else 0.0
        for cls, val in by_class.items()
    }

    # Risk = value-weighted blend of per-class risk weights.
    risk = sum(
        (val / total_value) * _RISK_WEIGHT.get(cls, 50)
        for cls, val in by_class.items()
    ) if total_value else 0.0

    # Diversification = 1 - Herfindahl concentration, scaled to 0–100.
    hhi = sum((val / total_value) ** 2 for val in by_class.values()) if total_value else 1.0
    diversification = (1 - hhi) * 100

    return PortfolioMetrics(
        total_value=round(total_value, 2),
        total_invested=round(total_invested, 2),
        total_gain=round(gain, 2),
        gain_pct=round(gain / total_invested * 100, 2) if total_invested else 0.0,
        allocation=allocation,
        risk_score=int(round(risk)),
        diversification_score=int(round(diversification)),
    )


def risk_label(score: int) -> str:
    if score >= 66:
        return "high"
    if score >= 40:
        return "moderate"
    return "low"
