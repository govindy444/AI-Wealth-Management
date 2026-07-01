"""Spending Analytics business logic: categorize → aggregate → explain.

Computes a monthly spend summary (category breakdown, month-over-month trend, an
explainable insight), paginated transactions, and budget progress. The insight
is rule-based today; the LLM narrative slots in at Module 21.
"""
from __future__ import annotations

from collections import defaultdict
from datetime import date

from app.models.spending import Budget, SpendCategory, Transaction
from app.repositories.spending_repository import SpendingRepository
from app.schemas.banking import ExplanationOut
from app.schemas.spending import (
    BudgetOut,
    CategorySpendOut,
    SpendingSummaryOut,
    TransactionOut,
    TransactionsPageOut,
)


def _prev_month(year: int, month: int) -> tuple[int, int]:
    return (year - 1, 12) if month == 1 else (year, month - 1)


class SpendingService:
    def __init__(self, repo: SpendingRepository) -> None:
        self._repo = repo

    @staticmethod
    def _resolve(year: int | None, month: int | None) -> tuple[int, int]:
        if year is not None and month is not None:
            return year, month
        today = date.today()
        return today.year, today.month

    async def summary(
        self, user_id: str, year: int | None, month: int | None
    ) -> SpendingSummaryOut:
        y, m = self._resolve(year, month)
        py, pm = _prev_month(y, m)

        txns = await self._repo.list_transactions(user_id, y, m)
        prev_txns = await self._repo.list_transactions(user_id, py, pm)

        spends = [t for t in txns if t.is_spend]
        total_spent = round(sum(t.amount for t in spends), 2)
        total_income = round(
            sum(t.amount for t in txns if t.category == SpendCategory.income), 2
        )
        prev_spent = round(
            sum(t.amount for t in prev_txns if t.is_spend), 2
        )
        change_pct = round(
            ((total_spent - prev_spent) / prev_spent * 100) if prev_spent else 0.0, 1
        )

        by_cat: dict[SpendCategory, float] = defaultdict(float)
        by_merchant: dict[str, float] = defaultdict(float)
        for t in spends:
            by_cat[t.category] += t.amount
            by_merchant[t.merchant] += t.amount

        categories = [
            CategorySpendOut(
                category=cat,
                amount=round(amt, 2),
                percentage=round(amt / total_spent * 100, 1) if total_spent else 0.0,
            )
            for cat, amt in sorted(by_cat.items(), key=lambda kv: kv[1], reverse=True)
        ]
        top_merchants = [
            mk for mk, _ in sorted(by_merchant.items(), key=lambda kv: kv[1], reverse=True)[:3]
        ]

        return SpendingSummaryOut(
            month=f"{y}-{m:02d}",
            total_spent=total_spent,
            total_income=total_income,
            net=round(total_income - total_spent, 2),
            previous_month_spent=prev_spent,
            change_pct=change_pct,
            categories=categories,
            top_merchants=top_merchants,
            insight=self._insight(total_spent, prev_spent, change_pct, categories),
        )

    async def transactions(
        self,
        user_id: str,
        year: int | None,
        month: int | None,
        category: SpendCategory | None,
        limit: int,
        offset: int,
    ) -> TransactionsPageOut:
        y, m = self._resolve(year, month)
        items = await self._repo.list_transactions(user_id, y, m, category)
        page = items[offset : offset + limit]
        return TransactionsPageOut(
            items=[self._to_txn_out(t) for t in page],
            total=len(items),
        )

    async def budgets(
        self, user_id: str, year: int | None, month: int | None
    ) -> list[BudgetOut]:
        y, m = self._resolve(year, month)
        txns = await self._repo.list_transactions(user_id, y, m)
        budgets = await self._repo.get_budgets(user_id)
        spent_by_cat: dict[SpendCategory, float] = defaultdict(float)
        for t in txns:
            if t.is_spend:
                spent_by_cat[t.category] += t.amount
        return [self._to_budget_out(b, spent_by_cat[b.category]) for b in budgets]

    async def set_budget(
        self, user_id: str, category: SpendCategory, monthly_limit: float
    ) -> BudgetOut:
        budget = await self._repo.set_budget(user_id, category, monthly_limit)
        today = date.today()
        txns = await self._repo.list_transactions(user_id, today.year, today.month, category)
        spent = sum(t.amount for t in txns if t.is_spend)
        return self._to_budget_out(budget, spent)

    # ── helpers ──────────────────────────────────────────────────
    @staticmethod
    def _to_txn_out(t: Transaction) -> TransactionOut:
        return TransactionOut(
            id=t.id,
            date=t.date,
            merchant=t.merchant,
            amount=t.amount,
            direction=t.direction,
            category=t.category,
        )

    @staticmethod
    def _to_budget_out(b: Budget, spent: float) -> BudgetOut:
        spent = round(spent, 2)
        used_pct = round(spent / b.monthly_limit * 100, 1) if b.monthly_limit else 0.0
        if used_pct >= 100:
            status = "over"
        elif used_pct >= 80:
            status = "near"
        else:
            status = "under"
        return BudgetOut(
            category=b.category,
            monthly_limit=b.monthly_limit,
            spent=spent,
            remaining=round(b.monthly_limit - spent, 2),
            used_pct=used_pct,
            status=status,
        )

    @staticmethod
    def _insight(
        total_spent: float,
        prev_spent: float,
        change_pct: float,
        categories: list[CategorySpendOut],
    ) -> ExplanationOut:
        top = categories[0] if categories else None
        direction = "up" if change_pct >= 0 else "down"
        summary = (
            f"You've spent ₹{total_spent:,.0f} this month, "
            f"{direction} {abs(change_pct):.0f}% vs last month."
        )
        reasons: list[str] = []
        risks: list[str] = []
        alternatives: list[str] = []
        if top:
            reasons.append(
                f"{top.category.value.title()} is your biggest category at "
                f"₹{top.amount:,.0f} ({top.percentage:.0f}% of spend)."
            )
        if change_pct > 10:
            risks.append("Spending is rising noticeably — review discretionary categories.")
            alternatives.append(
                "Set a budget on your top category to get alerts before you overspend."
            )
        elif change_pct < 0:
            reasons.append("Spending is lower than last month — nice control.")

        return ExplanationOut(
            summary=summary,
            reasons=reasons,
            risks=risks,
            benefits=[],
            alternatives=alternatives,
            citations=["Transactions for the selected month."],
            confidence=0.78,
        )
