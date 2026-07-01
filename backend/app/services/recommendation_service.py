"""Investment recommendation business logic.

A rule-based engine maps a risk profile to a target allocation across the product
shelf, sizes each holding to the investable amount, and attaches an Explainable-AI
rationale to every recommendation (and to the overall strategy). Module 21/22 can
replace `_ALLOCATIONS` and the rationale text with an LLM grounded (RAG) on IDBI
product documents — the response contract stays identical.
"""
from __future__ import annotations

from app.models.investment import InvestmentProduct, ProductType, RiskLevel, RiskProfile
from app.repositories.investment_repository import InvestmentRepository
from app.schemas.banking import ExplanationOut
from app.schemas.recommendations import (
    InvestmentProductOut,
    RecommendationOut,
    RecommendationSetOut,
)

# Target allocation per risk profile: (product_id, percent). Each list sums to 100.
_ALLOCATIONS: dict[RiskProfile, list[tuple[str, float]]] = {
    RiskProfile.conservative: [
        ("idbi_fd", 40),
        ("idbi_short_debt", 30),
        ("idbi_nifty_index", 20),
        ("idbi_gold_etf", 10),
    ],
    RiskProfile.moderate: [
        ("idbi_nifty_index", 30),
        ("idbi_hybrid", 25),
        ("idbi_short_debt", 30),
        ("idbi_gold_etf", 15),
    ],
    RiskProfile.aggressive: [
        ("idbi_bluechip_equity", 35),
        ("idbi_nifty_index", 30),
        ("idbi_elss", 20),
        ("idbi_gold_etf", 15),
    ],
}

_ROLE = {
    ProductType.index_fund: "growth engine",
    ProductType.equity_fund: "growth engine",
    ProductType.elss: "tax-saving growth",
    ProductType.debt_fund: "stability anchor",
    ProductType.fixed_deposit: "capital-safe anchor",
    ProductType.hybrid_fund: "balanced core",
    ProductType.gold: "diversifier & inflation hedge",
}

_RISK_NOTE = {
    RiskLevel.low: "Low risk — capital is relatively protected.",
    RiskLevel.moderate: "Moderate risk — expect some short-term ups and downs.",
    RiskLevel.high: "Higher risk — can be volatile short-term, rewards patience.",
}


class RecommendationService:
    def __init__(self, repo: InvestmentRepository) -> None:
        self._repo = repo

    async def list_products(self) -> list[InvestmentProductOut]:
        products = await self._repo.list_products()
        return [self._to_product_out(p) for p in products]

    async def recommend(
        self, risk_profile: RiskProfile, amount: float, horizon_years: int
    ) -> RecommendationSetOut:
        allocation = _ALLOCATIONS[risk_profile]
        recommendations: list[RecommendationOut] = []
        blended = 0.0

        for product_id, pct in allocation:
            product = await self._repo.get(product_id)
            if product is None:
                continue
            blended += product.expected_return * (pct / 100)
            recommendations.append(
                RecommendationOut(
                    product=self._to_product_out(product),
                    allocation_pct=pct,
                    suggested_amount=round(amount * pct / 100, 2),
                    rationale=self._rationale(product, risk_profile, pct),
                )
            )

        return RecommendationSetOut(
            risk_profile=risk_profile,
            total_amount=amount,
            horizon_years=horizon_years,
            blended_expected_return=round(blended, 4),
            recommendations=recommendations,
            insight=self._strategy_insight(
                risk_profile, amount, horizon_years, blended
            ),
        )

    # ── rationale builders ───────────────────────────────────────
    @staticmethod
    def _rationale(
        product: InvestmentProduct, profile: RiskProfile, pct: float
    ) -> ExplanationOut:
        role = _ROLE.get(product.type, "portfolio holding")
        return ExplanationOut(
            summary=f"{pct:.0f}% to {product.name} — your {role}.",
            reasons=[
                product.description,
                f"Fits a {profile.value} profile at a {pct:.0f}% weight.",
            ],
            risks=[_RISK_NOTE[product.risk_level]],
            benefits=[f"Targets about {product.expected_return:.0%} p.a. over the long run."],
            alternatives=[],
            citations=[f"IDBI product sheet: {product.name}."],
            confidence=0.7,
        )

    @staticmethod
    def _strategy_insight(
        profile: RiskProfile, amount: float, horizon: int, blended: float
    ) -> ExplanationOut:
        return ExplanationOut(
            summary=(
                f"A {profile.value} portfolio of ₹{amount:,.0f} targets about "
                f"{blended:.1%} a year over {horizon} years."
            ),
            reasons=[
                "Diversified across equity, debt, and gold to balance growth and stability.",
                "Allocation is matched to your stated risk appetite.",
            ],
            risks=[
                "Returns are not guaranteed; market-linked holdings can fall short-term.",
            ],
            benefits=[
                "Spreading across asset classes reduces the impact of any single one.",
            ],
            alternatives=[
                "Automate this as a monthly SIP and review the mix once a year.",
            ],
            citations=["Rule-based allocation model (not personalised investment advice)."],
            confidence=0.72,
        )

    @staticmethod
    def _to_product_out(p: InvestmentProduct) -> InvestmentProductOut:
        return InvestmentProductOut(
            id=p.id,
            name=p.name,
            type=p.type,
            risk_level=p.risk_level,
            expected_return=p.expected_return,
            min_investment=p.min_investment,
            description=p.description,
            tags=p.tags,
        )
