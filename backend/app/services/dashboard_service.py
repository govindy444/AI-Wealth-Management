"""Dashboard business logic: aggregate accounts into a net-worth summary and a
deterministic, explainable insight.

The insight is rule-based for now (no LLM call) but already ships the full
Explainable-AI envelope so the UI and SDK contract are exercised end-to-end. The
LLM-backed insight generator replaces `_build_insight` in Module 21 without
changing the response shape.
"""
from __future__ import annotations

from app.models.account import Account, AccountType
from app.models.user import User
from app.repositories.account_repository import AccountRepository
from app.schemas.banking import AccountOut, DashboardResponse, ExplanationOut


class DashboardService:
    def __init__(self, accounts: AccountRepository) -> None:
        self._accounts = accounts

    async def get_dashboard(self, user: User) -> DashboardResponse:
        accounts = await self._accounts.list_for_user(user.id)

        total_assets = sum(a.balance for a in accounts if not a.type.is_liability)
        total_liabilities = sum(a.balance for a in accounts if a.type.is_liability)
        net_worth = total_assets - total_liabilities
        monthly_change = sum(a.signed_monthly_change for a in accounts)

        return DashboardResponse(
            user_id=user.id,
            full_name=user.full_name,
            currency=accounts[0].currency if accounts else "INR",
            net_worth=round(net_worth, 2),
            total_assets=round(total_assets, 2),
            total_liabilities=round(total_liabilities, 2),
            monthly_change=round(monthly_change, 2),
            accounts=[self._to_out(a) for a in accounts],
            insight=self._build_insight(
                net_worth, total_assets, total_liabilities, monthly_change, accounts
            ),
        )

    @staticmethod
    def _to_out(a: Account) -> AccountOut:
        return AccountOut(
            id=a.id,
            name=a.name,
            type=a.type,
            masked_number=a.masked_number,
            balance=a.balance,
            currency=a.currency,
            monthly_change=a.monthly_change,
            is_liability=a.type.is_liability,
        )

    @staticmethod
    def _build_insight(
        net_worth: float,
        total_assets: float,
        total_liabilities: float,
        monthly_change: float,
        accounts: list[Account],
    ) -> ExplanationOut:
        reasons: list[str] = []
        risks: list[str] = []
        benefits: list[str] = []
        alternatives: list[str] = []

        debt_ratio = (total_liabilities / total_assets) if total_assets else 0.0
        idle_cash = sum(
            a.balance
            for a in accounts
            if a.type in {AccountType.savings, AccountType.current}
        )

        trend = "grew" if monthly_change >= 0 else "dipped"
        summary = (
            f"Your net worth {trend} by ₹{abs(monthly_change):,.0f} this month "
            f"to ₹{net_worth:,.0f}."
        )

        reasons.append(
            f"Assets of ₹{total_assets:,.0f} against liabilities of "
            f"₹{total_liabilities:,.0f} (debt-to-asset ratio {debt_ratio:.0%})."
        )
        if monthly_change >= 0:
            benefits.append("Positive monthly trend — your savings are compounding.")
        else:
            risks.append("Spending outpaced income this month; review discretionary outflows.")

        if debt_ratio > 0.4:
            risks.append(
                "Debt is a high share of assets; prioritising repayment lowers interest drag."
            )
            alternatives.append("Redirect surplus cash toward the highest-interest balance.")

        if idle_cash > 200_000:
            alternatives.append(
                f"₹{idle_cash:,.0f} sits in low-yield savings/current accounts — "
                "a sweep into deposits or liquid funds could earn more."
            )

        # Confidence reflects how much signal the rules had to work with.
        confidence = 0.6 + min(len(accounts), 6) * 0.05

        return ExplanationOut(
            summary=summary,
            reasons=reasons,
            risks=risks,
            benefits=benefits,
            alternatives=alternatives,
            citations=["Account balances as of the latest sync."],
            confidence=round(min(confidence, 0.95), 2),
        )
