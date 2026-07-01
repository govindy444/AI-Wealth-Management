"""Portfolio domain models: investment holdings and asset classes.

Lightweight dataclasses for the in-memory phase. Allocation, performance, and the
risk/diversification scores are computed by the portfolio engine, not stored.
"""
from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class AssetClass(str, Enum):
    equity = "equity"
    debt = "debt"
    gold = "gold"
    cash = "cash"
    real_estate = "real_estate"


@dataclass
class Holding:
    id: str
    user_id: str
    name: str
    asset_class: AssetClass
    invested: float        # cost basis
    current_value: float

    @property
    def gain(self) -> float:
        return self.current_value - self.invested

    @property
    def gain_pct(self) -> float:
        return (self.gain / self.invested * 100) if self.invested else 0.0
