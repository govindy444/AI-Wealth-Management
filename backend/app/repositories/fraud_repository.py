"""Fraud monitoring repository + in-memory implementation.

Seeds recent card/account activity for the demo user — mostly normal, with a
couple of planted anomalies (an unusually large purchase and a duplicate charge)
so the detection engine has something to find. Module 20 swaps in a real feed.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from datetime import date, timedelta

from app.models.spending import SpendCategory, Transaction, TransactionDirection

_DEMO_UID = "usr_demo_0001"
_DEBIT = TransactionDirection.debit


class FraudRepository(ABC):
    @abstractmethod
    async def recent_transactions(self, user_id: str) -> list[Transaction]: ...


class InMemoryFraudRepository(FraudRepository):
    def __init__(self) -> None:
        self._by_user: dict[str, list[Transaction]] = {_DEMO_UID: self._seed()}

    @staticmethod
    def _seed() -> list[Transaction]:
        today = date.today()

        def d(days_ago: int) -> date:
            return today - timedelta(days=days_ago)

        # (merchant, amount, days_ago, category)
        rows = [
            ("Swiggy", 540.0, 1, SpendCategory.dining),
            ("Uber", 280.0, 2, SpendCategory.transport),
            ("BigBasket", 2100.0, 3, SpendCategory.groceries),
            ("Amazon", 1899.0, 4, SpendCategory.shopping),
            # Planted anomaly: unusually large electronics purchase to a new merchant.
            ("QuickElectronics Online", 48999.0, 1, SpendCategory.shopping),
            # Planted anomaly: duplicate charge (same merchant + amount, same day).
            ("PayFast Services", 2999.0, 2, SpendCategory.other),
            ("PayFast Services", 2999.0, 2, SpendCategory.other),
            ("Netflix", 649.0, 5, SpendCategory.entertainment),
        ]
        return [
            Transaction(
                id=f"frd_{i:03d}",
                user_id=_DEMO_UID,
                date=d(days_ago),
                merchant=merchant,
                amount=amount,
                direction=_DEBIT,
                category=category,
            )
            for i, (merchant, amount, days_ago, category) in enumerate(rows)
        ]

    async def recent_transactions(self, user_id: str) -> list[Transaction]:
        return list(self._by_user.get(user_id, []))


_singleton = InMemoryFraudRepository()


def get_fraud_repository() -> FraudRepository:
    return _singleton
