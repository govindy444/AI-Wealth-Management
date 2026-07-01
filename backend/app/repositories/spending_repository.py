"""Spending repository abstraction + in-memory implementation.

Seeds three months of realistic, auto-categorized transactions for the demo user
(anchored to the current date so trends always have data) plus a few default
category budgets. Module 20 swaps in a Postgres-backed implementation.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from datetime import date

from app.models.spending import (
    Budget,
    SpendCategory,
    Transaction,
    TransactionDirection,
)
from app.services.spending_categorizer import RuleBasedCategorizer

_DEMO_UID = "usr_demo_0001"

# (merchant, amount, direction, day-of-month). Categories are derived by the
# categorizer at seed time, so categorization is genuinely exercised.
_DEBIT = TransactionDirection.debit
_CREDIT = TransactionDirection.credit
_TEMPLATE: list[tuple[str, float, TransactionDirection, int]] = [
    ("ACME Corp Salary", 145000.0, _CREDIT, 1),
    ("Sunrise Apartments Rent", 32000.0, _DEBIT, 2),
    ("BigBasket", 4200.0, _DEBIT, 4),
    ("DMart", 3100.0, _DEBIT, 18),
    ("Swiggy", 680.0, _DEBIT, 6),
    ("Zomato", 950.0, _DEBIT, 13),
    ("Starbucks", 540.0, _DEBIT, 20),
    ("Uber", 320.0, _DEBIT, 7),
    ("HP Petrol Pump Fuel", 2600.0, _DEBIT, 9),
    ("Airtel Broadband", 1199.0, _DEBIT, 11),
    ("Electricity Board", 1850.0, _DEBIT, 12),
    ("Amazon", 3499.0, _DEBIT, 15),
    ("Myntra", 2299.0, _DEBIT, 22),
    ("Netflix", 649.0, _DEBIT, 3),
    ("Apollo Pharmacy", 870.0, _DEBIT, 24),
]


def _shift_month(anchor: date, months_back: int) -> tuple[int, int]:
    y, m = anchor.year, anchor.month
    m -= months_back
    while m <= 0:
        m += 12
        y -= 1
    return y, m


class SpendingRepository(ABC):
    @abstractmethod
    async def list_transactions(
        self,
        user_id: str,
        year: int | None = None,
        month: int | None = None,
        category: SpendCategory | None = None,
    ) -> list[Transaction]: ...

    @abstractmethod
    async def get_budgets(self, user_id: str) -> list[Budget]: ...

    @abstractmethod
    async def set_budget(
        self, user_id: str, category: SpendCategory, monthly_limit: float
    ) -> Budget: ...


class InMemorySpendingRepository(SpendingRepository):
    def __init__(self) -> None:
        self._txns: dict[str, list[Transaction]] = {}
        self._budgets: dict[str, dict[SpendCategory, Budget]] = {}
        self._categorizer = RuleBasedCategorizer()
        self._seed()

    def _seed(self) -> None:
        today = date.today()
        txns: list[Transaction] = []
        seq = 0
        for offset in range(3):  # current + previous 2 months
            y, m = _shift_month(today, offset)
            for merchant, amount, direction, day in _TEMPLATE:
                seq += 1
                # The current month runs a little hotter on discretionary spend
                # so month-over-month trends are visible.
                bump = 1.15 if offset == 0 and direction == _DEBIT else 1.0
                txns.append(
                    Transaction(
                        id=f"txn_{y}{m:02d}_{seq:04d}",
                        user_id=_DEMO_UID,
                        date=date(y, m, min(day, 28)),
                        merchant=merchant,
                        amount=round(amount * bump, 2),
                        direction=direction,
                        category=self._categorizer.categorize(merchant, direction),
                    )
                )
        # Extra discretionary spend this month to push the trend up.
        cy, cm = _shift_month(today, 0)
        txns.append(
            Transaction(
                id=f"txn_{cy}{cm:02d}_extra",
                user_id=_DEMO_UID,
                date=date(cy, cm, min(26, 28)),
                merchant="Flipkart",
                amount=5499.0,
                direction=_DEBIT,
                category=self._categorizer.categorize("Flipkart", _DEBIT),
            )
        )
        self._txns[_DEMO_UID] = txns

        self._budgets[_DEMO_UID] = {
            SpendCategory.dining: Budget(SpendCategory.dining, 4000.0),
            SpendCategory.shopping: Budget(SpendCategory.shopping, 6000.0),
            SpendCategory.groceries: Budget(SpendCategory.groceries, 9000.0),
            SpendCategory.entertainment: Budget(SpendCategory.entertainment, 1500.0),
        }

    async def list_transactions(
        self,
        user_id: str,
        year: int | None = None,
        month: int | None = None,
        category: SpendCategory | None = None,
    ) -> list[Transaction]:
        items = [t for t in self._txns.get(user_id, [])]
        if year is not None and month is not None:
            items = [t for t in items if t.date.year == year and t.date.month == month]
        if category is not None:
            items = [t for t in items if t.category == category]
        return sorted(items, key=lambda t: t.date, reverse=True)

    async def get_budgets(self, user_id: str) -> list[Budget]:
        return list(self._budgets.get(user_id, {}).values())

    async def set_budget(
        self, user_id: str, category: SpendCategory, monthly_limit: float
    ) -> Budget:
        budget = Budget(category=category, monthly_limit=monthly_limit)
        self._budgets.setdefault(user_id, {})[category] = budget
        return budget


_singleton = InMemorySpendingRepository()


def get_spending_repository() -> SpendingRepository:
    return _singleton
