"""Banking account domain model.

A lightweight dataclass for the in-memory phase; the SQLAlchemy mapping lands in
Module 20. `kind` distinguishes asset accounts (count positively toward net
worth) from liability accounts (credit cards, loans) which count negatively.
"""
from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class AccountType(str, Enum):
    savings = "savings"
    current = "current"
    deposit = "deposit"  # fixed/recurring deposit
    mutual_fund = "mutual_fund"
    credit_card = "credit_card"
    loan = "loan"

    @property
    def is_liability(self) -> bool:
        return self in {AccountType.credit_card, AccountType.loan}


@dataclass
class Account:
    id: str
    user_id: str
    name: str
    type: AccountType
    # Last four digits only; full numbers are never stored in the demo backend.
    masked_number: str
    # Balance in the account's own currency. For liabilities this is the amount
    # owed (a positive number) and is subtracted from net worth.
    balance: float
    currency: str = "INR"
    # Net change over the trailing 30 days, used for the dashboard trend.
    monthly_change: float = 0.0
    is_active: bool = True

    @property
    def signed_balance(self) -> float:
        """Balance contribution to net worth (liabilities are negative)."""
        return -self.balance if self.type.is_liability else self.balance

    @property
    def signed_monthly_change(self) -> float:
        """Monthly change's contribution to net worth.

        A rising asset balance helps net worth; a rising liability balance hurts
        it, so the liability change is inverted.
        """
        return -self.monthly_change if self.type.is_liability else self.monthly_change
