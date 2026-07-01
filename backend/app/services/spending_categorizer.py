"""Transaction auto-categorization.

`SpendingCategorizer` is the seam between raw transactions and their spending
category. `RuleBasedCategorizer` (today) maps merchant keywords to categories;
Module 21 can drop in an ML classifier behind the same interface.
"""
from __future__ import annotations

from abc import ABC, abstractmethod

from app.models.spending import SpendCategory, TransactionDirection

# Ordered keyword → category rules (first match wins).
_RULES: list[tuple[tuple[str, ...], SpendCategory]] = [
    (("salary", "payroll"), SpendCategory.income),
    (("rent", "landlord"), SpendCategory.rent),
    (("bigbasket", "dmart", "grocery", "grofers", "blinkit", "reliance fresh"),
     SpendCategory.groceries),
    (("swiggy", "zomato", "cafe", "restaurant", "dominos", "starbucks"),
     SpendCategory.dining),
    (("uber", "ola", "fuel", "petrol", "metro", "irctc", "rapido"),
     SpendCategory.transport),
    (("electricity", "mobile", "broadband", "gas", "water", "airtel", "jio"),
     SpendCategory.utilities),
    (("amazon", "flipkart", "myntra", "ajio", "nykaa"), SpendCategory.shopping),
    (("netflix", "bookmyshow", "spotify", "hotstar", "prime video"),
     SpendCategory.entertainment),
    (("pharmacy", "apollo", "hospital", "clinic", "1mg", "medplus"),
     SpendCategory.health),
    (("upi", "transfer", "neft", "imps", "self"), SpendCategory.transfer),
]


class SpendingCategorizer(ABC):
    @abstractmethod
    def categorize(self, merchant: str, direction: TransactionDirection) -> SpendCategory: ...


class RuleBasedCategorizer(SpendingCategorizer):
    def categorize(self, merchant: str, direction: TransactionDirection) -> SpendCategory:
        text = merchant.lower()
        for keywords, category in _RULES:
            if any(k in text for k in keywords):
                return category
        # Unknown credits are treated as income; unknown debits as 'other'.
        return (
            SpendCategory.income
            if direction == TransactionDirection.credit
            else SpendCategory.other
        )
