"""Portfolio Intelligence business logic.

Pulls holdings, runs the pure [portfolio_engine], and assembles a summary with an
allocation breakdown, top holdings, and a rebalancing-oriented explainable insight.
"""
from __future__ import annotations

from app.models.portfolio import AssetClass, Holding
from app.models.user import User
from app.repositories.portfolio_repository import PortfolioRepository
from app.schemas.banking import ExplanationOut
from app.schemas.portfolio import (
    AllocationSliceOut,
    HoldingOut,
    PortfolioSummaryOut,
)
from app.services import portfolio_engine

# A reasonable "balanced" target equity weight to measure drift against.
_TARGET_EQUITY = 50.0
_DRIFT = 15.0


class PortfolioService:
    def __init__(self, repo: PortfolioRepository) -> None:
        self._repo = repo

    async def list_holdings(self, user: User) -> list[HoldingOut]:
        holdings = await self._repo.list_holdings(user.id)
        return [self._to_holding_out(h) for h in holdings]

    async def summary(self, user: User) -> PortfolioSummaryOut:
        holdings = await self._repo.list_holdings(user.id)
        m = portfolio_engine.compute(holdings)

        allocation = [
            AllocationSliceOut(
                asset_class=cls,
                percentage=pct,
                value=round(pct / 100 * m.total_value, 2),
            )
            for cls, pct in sorted(
                m.allocation.items(), key=lambda kv: kv[1], reverse=True
            )
        ]
        top = sorted(holdings, key=lambda h: h.current_value, reverse=True)[:3]
        equity_pct = m.allocation.get(AssetClass.equity, 0.0)

        return PortfolioSummaryOut(
            total_value=m.total_value,
            total_invested=m.total_invested,
            total_gain=m.total_gain,
            gain_pct=m.gain_pct,
            risk_score=m.risk_score,
            risk_label=portfolio_engine.risk_label(m.risk_score),
            diversification_score=m.diversification_score,
            allocation=allocation,
            top_holdings=[self._to_holding_out(h) for h in top],
            insight=self._insight(m, equity_pct),
        )

    @staticmethod
    def _to_holding_out(h: Holding) -> HoldingOut:
        return HoldingOut(
            id=h.id,
            name=h.name,
            asset_class=h.asset_class,
            invested=h.invested,
            current_value=h.current_value,
            gain=round(h.gain, 2),
            gain_pct=round(h.gain_pct, 2),
        )

    @staticmethod
    def _insight(
        m: portfolio_engine.PortfolioMetrics, equity_pct: float
    ) -> ExplanationOut:
        label = portfolio_engine.risk_label(m.risk_score)
        summary = (
            f"Your portfolio is worth ₹{m.total_value:,.0f} "
            f"({'up' if m.total_gain >= 0 else 'down'} {abs(m.gain_pct):.1f}%), "
            f"with a {label} risk profile."
        )
        reasons = [
            f"Equity is {equity_pct:.0f}% of the portfolio; "
            f"diversification score {m.diversification_score}/100.",
        ]
        risks: list[str] = []
        alternatives: list[str] = []

        if equity_pct > _TARGET_EQUITY + _DRIFT:
            risks.append("Equity-heavy — more exposed to market swings.")
            alternatives.append(
                f"Consider trimming equity toward ~{_TARGET_EQUITY:.0f}% and adding debt."
            )
        elif equity_pct < _TARGET_EQUITY - _DRIFT:
            alternatives.append(
                f"Equity is light for long-term growth; consider raising it toward "
                f"~{_TARGET_EQUITY:.0f}%."
            )
        else:
            reasons.append("Allocation is close to a balanced target — well diversified.")

        if m.diversification_score < 40:
            risks.append("Concentrated in a few holdings; spreading out lowers risk.")

        return ExplanationOut(
            summary=summary,
            reasons=reasons,
            risks=risks,
            benefits=["Diversification across asset classes cushions any single market."],
            alternatives=alternatives,
            citations=["Computed from your current holdings."],
            confidence=0.8,
        )
