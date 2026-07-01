"""Spending domain models: transactions, categories, and budgets.

Lightweight dataclasses for the in-memory phase. Auto-categorization is done by
the SpendingCategorizer service (rule-based today; an ML classifier slots in at
Module 21 behind the same contract).
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from enum import Enum


class TransactionDirection(str, Enum):
    debit = "debit"   # money out
    credit = "credit"  # money in


class SpendCategory(str, Enum):
    groceries = "groceries"
    dining = "dining"
    transport = "transport"
    utilities = "utilities"
    shopping = "shopping"
    entertainment = "entertainment"
    health = "health"
    rent = "rent"
    income = "income"
    transfer = "transfer"
    other = "other"


@dataclass
class Transaction:
    id: str
    user_id: str
    date: date
    merchant: str
    amount: float  # always positive; direction carries the sign meaning
    direction: TransactionDirection
    category: SpendCategory = SpendCategory.other

    @property
    def is_spend(self) -> bool:
        """A debit that isn't an internal transfer counts as spending."""
        return (
            self.direction == TransactionDirection.debit
            and self.category != SpendCategory.transfer
        )


@dataclass
class Budget:
    category: SpendCategory
    monthly_limit: float
