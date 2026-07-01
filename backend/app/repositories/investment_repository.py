"""Investment product catalog repository + in-memory implementation.

Seeded with a representative IDBI-branded product shelf across risk levels.
Module 20 can move this to the database / an external product feed.
"""
from __future__ import annotations

from abc import ABC, abstractmethod

from app.models.investment import InvestmentProduct, ProductType, RiskLevel


class InvestmentRepository(ABC):
    @abstractmethod
    async def list_products(self) -> list[InvestmentProduct]: ...

    @abstractmethod
    async def get(self, product_id: str) -> InvestmentProduct | None: ...


class InMemoryInvestmentRepository(InvestmentRepository):
    def __init__(self) -> None:
        self._products: dict[str, InvestmentProduct] = {
            p.id: p for p in self._seed()
        }

    @staticmethod
    def _seed() -> list[InvestmentProduct]:
        return [
            InvestmentProduct(
                id="idbi_nifty_index",
                name="IDBI Nifty 50 Index Fund",
                type=ProductType.index_fund,
                risk_level=RiskLevel.moderate,
                expected_return=0.11,
                min_investment=500,
                description="Low-cost fund tracking the Nifty 50 — broad equity exposure.",
                tags=["equity", "passive", "long-term"],
            ),
            InvestmentProduct(
                id="idbi_bluechip_equity",
                name="IDBI Bluechip Equity Fund",
                type=ProductType.equity_fund,
                risk_level=RiskLevel.high,
                expected_return=0.13,
                min_investment=1000,
                description="Actively-managed large-cap equity fund for long-term growth.",
                tags=["equity", "growth"],
            ),
            InvestmentProduct(
                id="idbi_elss",
                name="IDBI Tax Saver (ELSS)",
                type=ProductType.elss,
                risk_level=RiskLevel.high,
                expected_return=0.12,
                min_investment=500,
                description="Equity fund with a 3-year lock-in and 80C tax benefit.",
                tags=["equity", "tax-saving", "80C"],
            ),
            InvestmentProduct(
                id="idbi_short_debt",
                name="IDBI Short Duration Debt Fund",
                type=ProductType.debt_fund,
                risk_level=RiskLevel.low,
                expected_return=0.07,
                min_investment=500,
                description="Short-maturity bonds — stability with better-than-savings yield.",
                tags=["debt", "stable"],
            ),
            InvestmentProduct(
                id="idbi_hybrid",
                name="IDBI Balanced Advantage Fund",
                type=ProductType.hybrid_fund,
                risk_level=RiskLevel.moderate,
                expected_return=0.10,
                min_investment=1000,
                description="Dynamically balances equity and debt to smooth volatility.",
                tags=["hybrid", "balanced"],
            ),
            InvestmentProduct(
                id="idbi_fd",
                name="IDBI Fixed Deposit",
                type=ProductType.fixed_deposit,
                risk_level=RiskLevel.low,
                expected_return=0.065,
                min_investment=5000,
                description="Capital-guaranteed deposit with assured returns.",
                tags=["debt", "guaranteed", "capital-safe"],
            ),
            InvestmentProduct(
                id="idbi_gold_etf",
                name="IDBI Gold ETF",
                type=ProductType.gold,
                risk_level=RiskLevel.moderate,
                expected_return=0.08,
                min_investment=500,
                description="Gold exposure as an inflation hedge and diversifier.",
                tags=["gold", "hedge", "diversifier"],
            ),
        ]

    async def list_products(self) -> list[InvestmentProduct]:
        return list(self._products.values())

    async def get(self, product_id: str) -> InvestmentProduct | None:
        return self._products.get(product_id)


_singleton = InMemoryInvestmentRepository()


def get_investment_repository() -> InvestmentRepository:
    return _singleton
