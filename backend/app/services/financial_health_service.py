"""Financial Health business logic.

Composes the banking (accounts) and spending data, feeds the pure
[health_engine], and turns the scores into human-readable pillars with
recommendations plus an overall explainable insight. (Like the voice service
composing chat, this reuses existing module data rather than duplicating it.)
"""
from __future__ import annotations

from app.models.account import AccountType
from app.models.user import User
from app.repositories.account_repository import AccountRepository
from app.schemas.banking import ExplanationOut
from app.schemas.financial_health import FinancialHealthOut, HealthPillarOut
from app.services import health_engine as engine
from app.services.health_engine import HealthInputs
from app.services.spending_service import SpendingService

_LABELS = {
    engine.SAVINGS: "Savings",
    engine.DEBT: "Debt",
    engine.EMERGENCY_FUND: "Emergency Fund",
    engine.INVESTMENTS: "Investments",
    engine.SPENDING: "Spending Discipline",
}

_LIQUID_TYPES = {AccountType.savings, AccountType.current, AccountType.deposit}


class FinancialHealthService:
    def __init__(self, accounts: AccountRepository, spending: SpendingService) -> None:
        self._accounts = accounts
        self._spending = spending

    async def score(self, user: User) -> FinancialHealthOut:
        accounts = await self._accounts.list_for_user(user.id)
        summary = await self._spending.summary(user.id, None, None)

        total_assets = sum(a.balance for a in accounts if not a.type.is_liability)
        total_liabilities = sum(a.balance for a in accounts if a.type.is_liability)
        liquid = sum(a.balance for a in accounts if a.type in _LIQUID_TYPES)
        investments = sum(
            a.balance for a in accounts if a.type == AccountType.mutual_fund
        )

        inputs = HealthInputs(
            total_assets=total_assets,
            total_liabilities=total_liabilities,
            liquid_assets=liquid,
            investment_assets=investments,
            monthly_income=summary.total_income,
            monthly_spent=summary.total_spent,
            spend_change_pct=summary.change_pct,
        )
        result = engine.compute(inputs)
        pillars = [self._pillar(key, result.pillar_scores[key], inputs) for key in _LABELS]

        return FinancialHealthOut(
            score=result.overall,
            grade=engine.grade_for(result.overall),
            status=engine.status_for(result.overall),
            pillars=pillars,
            insight=self._insight(result.overall, pillars),
        )

    # ── pillar text ──────────────────────────────────────────────
    def _pillar(self, key: str, score: int, inp: HealthInputs) -> HealthPillarOut:
        status = engine.status_for(score)
        detail, recommendation = self._explain(key, score, inp)
        return HealthPillarOut(
            key=key,
            label=_LABELS[key],
            score=score,
            status=status,
            detail=detail,
            recommendation=recommendation,
        )

    @staticmethod
    def _explain(key: str, score: int, inp: HealthInputs) -> tuple[str, str]:
        weak = score < 60
        if key == engine.SAVINGS:
            rate = (inp.monthly_income - inp.monthly_spent) / inp.monthly_income * 100 \
                if inp.monthly_income > 0 else 0.0
            return (
                f"You're saving about {rate:.0f}% of your income.",
                "Automate a transfer of at least 20% of income on payday."
                if weak else "Strong savings rate — keep automating it.",
            )
        if key == engine.DEBT:
            ratio = inp.total_liabilities / inp.total_assets * 100 if inp.total_assets else 0.0
            return (
                f"Your debts are {ratio:.0f}% of your assets.",
                "Prioritise paying down the highest-interest debt first."
                if weak else "Your debt is well-controlled.",
            )
        if key == engine.EMERGENCY_FUND:
            months = inp.liquid_assets / inp.monthly_spent if inp.monthly_spent else 6.0
            return (
                f"You have about {months:.1f} months of expenses in liquid savings.",
                "Build toward 6 months of expenses in an accessible account."
                if weak else "You have a solid emergency buffer.",
            )
        if key == engine.INVESTMENTS:
            share = inp.investment_assets / inp.total_assets * 100 if inp.total_assets else 0.0
            return (
                f"{share:.0f}% of your assets are invested for growth.",
                "Move some idle cash into diversified funds for long-term growth."
                if weak else "Healthy growth allocation.",
            )
        # SPENDING
        return (
            f"Your spending is {'up' if inp.spend_change_pct >= 0 else 'down'} "
            f"{abs(inp.spend_change_pct):.0f}% this month.",
            "Review discretionary categories and set budgets with alerts."
            if weak else "Your spending is under control.",
        )

    @staticmethod
    def _insight(overall: int, pillars: list[HealthPillarOut]) -> ExplanationOut:
        ranked = sorted(pillars, key=lambda p: p.score)
        weakest = ranked[0]
        strongest = ranked[-1]
        return ExplanationOut(
            summary=(
                f"Your financial health is {engine.status_for(overall)} "
                f"({overall}/100, grade {engine.grade_for(overall)})."
            ),
            reasons=[f"Strongest area: {strongest.label} ({strongest.score}/100)."],
            risks=[f"Weakest area: {weakest.label} ({weakest.score}/100)."],
            benefits=[],
            alternatives=[weakest.recommendation],
            citations=["Computed from your accounts and this month's spending."],
            confidence=0.82,
        )
