"""Account repository abstraction + in-memory implementation.

Seeded with a realistic spread of accounts for the demo user so the dashboard
renders end-to-end before the database lands (Module 20). Services depend on
[AccountRepository], so the Postgres-backed implementation can be dropped in
without touching business logic.
"""
from __future__ import annotations

from abc import ABC, abstractmethod

from app.models.account import Account, AccountType


class AccountRepository(ABC):
    @abstractmethod
    async def list_for_user(self, user_id: str) -> list[Account]: ...


class InMemoryAccountRepository(AccountRepository):
    def __init__(self) -> None:
        self._by_user: dict[str, list[Account]] = {}
        self._seed_demo_accounts()

    def _seed_demo_accounts(self) -> None:
        uid = "usr_demo_0001"
        self._by_user[uid] = [
            Account(
                id="acc_sav_01",
                user_id=uid,
                name="IDBI Savings",
                type=AccountType.savings,
                masked_number="4821",
                balance=248_500.0,
                monthly_change=12_300.0,
            ),
            Account(
                id="acc_cur_01",
                user_id=uid,
                name="Salary Current A/C",
                type=AccountType.current,
                masked_number="9034",
                balance=86_200.0,
                monthly_change=-4_100.0,
            ),
            Account(
                id="acc_fd_01",
                user_id=uid,
                name="Fixed Deposit",
                type=AccountType.deposit,
                masked_number="1190",
                balance=500_000.0,
                monthly_change=3_120.0,
            ),
            Account(
                id="acc_mf_01",
                user_id=uid,
                name="Mutual Fund Portfolio",
                type=AccountType.mutual_fund,
                masked_number="7765",
                balance=362_840.0,
                monthly_change=18_640.0,
            ),
            Account(
                id="acc_cc_01",
                user_id=uid,
                name="IDBI Platinum Credit Card",
                type=AccountType.credit_card,
                masked_number="3302",
                balance=43_750.0,
                monthly_change=43_750.0,
            ),
            Account(
                id="acc_loan_01",
                user_id=uid,
                name="Home Loan",
                type=AccountType.loan,
                masked_number="5521",
                balance=520_000.0,
                monthly_change=-21_500.0,
            ),
        ]

    async def list_for_user(self, user_id: str) -> list[Account]:
        return list(self._by_user.get(user_id, []))


_singleton = InMemoryAccountRepository()


def get_account_repository() -> AccountRepository:
    return _singleton
