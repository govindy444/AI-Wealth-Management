"""Predictive Banking business logic.

Composes account balances (banking) and transaction history (spending), detects
recurring cashflows, injects loan EMIs from loan accounts, and runs the pure
prediction engine to produce a forward-looking forecast + explainable insight.
"""
from __future__ import annotations

from datetime import date

from app.models.account import AccountType
from app.models.prediction import (
    Prediction,
    PredictionType,
    RecurringItem,
    TransactionDirection,
)
from app.models.spending import SpendCategory
from app.models.user import User
from app.repositories.account_repository import AccountRepository
from app.repositories.spending_repository import SpendingRepository
from app.schemas.banking import ExplanationOut
from app.schemas.predictive import ForecastOut, PredictionOut
from app.services import prediction_engine

_LIQUID = {AccountType.savings, AccountType.current}


class PredictiveService:
    def __init__(
        self, accounts: AccountRepository, spending: SpendingRepository
    ) -> None:
        self._accounts = accounts
        self._spending = spending

    async def forecast(self, user: User) -> ForecastOut:
        today = date.today()
        accounts = await self._accounts.list_for_user(user.id)
        transactions = await self._spending.list_transactions(user.id)

        liquid = sum(a.balance for a in accounts if a.type in _LIQUID)

        recurring = prediction_engine.detect_recurring(transactions)
        # Inject loan EMIs (not present in spending transactions).
        for a in accounts:
            if a.type == AccountType.loan and a.monthly_change:
                recurring.append(RecurringItem(
                    label=a.name,
                    amount=abs(a.monthly_change),
                    direction=TransactionDirection.debit,
                    day=5,
                    category=SpendCategory.other,
                    is_loan=True,
                ))

        predictions = prediction_engine.build_predictions(liquid, recurring, today)
        projected = prediction_engine.project_month_end_balance(liquid, recurring, today)

        return ForecastOut(
            as_of=today,
            current_liquid_balance=round(liquid, 2),
            projected_month_end_balance=projected,
            predictions=[self._to_out(p) for p in predictions],
            insight=self._insight(predictions, liquid, projected),
        )

    @staticmethod
    def _to_out(p: Prediction) -> PredictionOut:
        return PredictionOut(
            type=p.type,
            title=p.title,
            message=p.message,
            predicted_date=p.predicted_date,
            days_away=p.days_away,
            severity=p.severity,
            amount=p.amount,
        )

    @staticmethod
    def _insight(
        predictions: list[Prediction], liquid: float, projected: float
    ) -> ExplanationOut:
        low = next((p for p in predictions if p.type == PredictionType.low_balance), None)
        bills = [
            p
            for p in predictions
            if p.type in (PredictionType.bill_due, PredictionType.emi_due)
        ]
        salary = next((p for p in predictions if p.type == PredictionType.salary_credit), None)

        if low is not None:
            summary = "Heads up — your balance is projected to run low before your next salary."
        elif projected >= liquid:
            summary = "Your cashflow looks healthy this month."
        else:
            summary = "A few payments are coming up; you're on track but keep an eye on spending."

        reasons = []
        if salary is not None:
            reasons.append(f"Next salary expected in {salary.days_away} days.")
        if bills:
            total = sum(p.amount or 0 for p in bills)
            reasons.append(f"{len(bills)} upcoming payment(s) totalling about ₹{total:,.0f}.")

        risks = [low.message] if low is not None else []
        alternatives = (
            ["Move surplus into a deposit after your bills clear." ]
            if low is None and projected > liquid else
            ["Delay non-essential purchases until after your salary credits."]
        )

        return ExplanationOut(
            summary=summary,
            reasons=reasons,
            risks=risks,
            benefits=[],
            alternatives=alternatives,
            citations=["Projected from your recent recurring transactions."],
            confidence=0.75,
        )
