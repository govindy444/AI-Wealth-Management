"""Portfolio holdings repository + in-memory implementation.

Seeded with a diversified set of holdings for the demo user. Module 20 swaps in a
Postgres-backed implementation (or a holdings feed from the bank's systems).
"""
from __future__ import annotations

from abc import ABC, abstractmethod

from app.models.portfolio import AssetClass, Holding

_DEMO_UID = "usr_demo_0001"


class PortfolioRepository(ABC):
    @abstractmethod
    async def list_holdings(self, user_id: str) -> list[Holding]: ...


class InMemoryPortfolioRepository(PortfolioRepository):
    def __init__(self) -> None:
        self._by_user: dict[str, list[Holding]] = {_DEMO_UID: self._seed()}

    @staticmethod
    def _seed() -> list[Holding]:
        rows = [
            ("hld_bluechip", "IDBI Bluechip Equity Fund", AssetClass.equity, 150_000, 182_000),
            ("hld_nifty", "IDBI Nifty 50 Index Fund", AssetClass.equity, 100_000, 118_000),
            ("hld_debt", "IDBI Short Duration Debt Fund", AssetClass.debt, 120_000, 128_000),
            ("hld_fd", "IDBI Fixed Deposit", AssetClass.debt, 200_000, 212_000),
            ("hld_gold", "IDBI Gold ETF", AssetClass.gold, 60_000, 67_000),
            ("hld_cash", "Liquid Savings", AssetClass.cash, 90_000, 90_000),
        ]
        return [
            Holding(
                id=i, user_id=_DEMO_UID, name=n, asset_class=ac,
                invested=float(inv), current_value=float(cur),
            )
            for (i, n, ac, inv, cur) in rows
        ]

    async def list_holdings(self, user_id: str) -> list[Holding]:
        return list(self._by_user.get(user_id, []))


_singleton = InMemoryPortfolioRepository()


def get_portfolio_repository() -> PortfolioRepository:
    return _singleton
