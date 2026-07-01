"""Goal Planner business logic: CRUD + projections via goal_math.

Each goal is returned with its computed projection (required SIP, projected value
at the current contribution, on-track flag). `simulate` powers "what would it
take?" planning without persisting a goal.
"""
from __future__ import annotations

from datetime import date

from app.core.exceptions import NotFoundError
from app.models.goal import Goal
from app.models.user import User
from app.repositories.goal_repository import GoalRepository
from app.schemas.banking import ExplanationOut
from app.schemas.goals import (
    CreateGoalRequest,
    GoalOut,
    SimulateRequest,
    SimulateResponse,
    UpdateGoalRequest,
)
from app.services import goal_math


class GoalService:
    def __init__(self, goals: GoalRepository) -> None:
        self._goals = goals

    async def list_goals(self, user: User) -> list[GoalOut]:
        goals = await self._goals.list_for_user(user.id)
        return [self._project(g) for g in goals]

    async def create_goal(self, user: User, req: CreateGoalRequest) -> GoalOut:
        goal = Goal(
            user_id=user.id,
            name=req.name,
            target_amount=req.target_amount,
            target_date=req.target_date,
            current_amount=req.current_amount,
            monthly_contribution=req.monthly_contribution,
            expected_return_rate=req.expected_return_rate,
            category=req.category,
        )
        return self._project(await self._goals.create(goal))

    async def get_goal(self, user: User, goal_id: str) -> GoalOut:
        return self._project(await self._require(user, goal_id))

    async def update_goal(
        self, user: User, goal_id: str, req: UpdateGoalRequest
    ) -> GoalOut:
        goal = await self._require(user, goal_id)
        if req.target_amount is not None:
            goal.target_amount = req.target_amount
        if req.current_amount is not None:
            goal.current_amount = req.current_amount
        if req.monthly_contribution is not None:
            goal.monthly_contribution = req.monthly_contribution
        if req.target_date is not None:
            goal.target_date = req.target_date
        if req.expected_return_rate is not None:
            goal.expected_return_rate = req.expected_return_rate
        return self._project(await self._goals.update(goal))

    async def delete_goal(self, user: User, goal_id: str) -> None:
        if not await self._goals.delete(user.id, goal_id):
            raise NotFoundError("Goal not found.")

    def simulate(self, req: SimulateRequest) -> SimulateResponse:
        months = goal_math.months_between(date.today(), req.target_date)
        required = goal_math.required_monthly(
            req.target_amount, req.current_amount, req.expected_return_rate, months
        )
        projected: float | None = None
        on_track = False
        if req.monthly_contribution is not None:
            projected = goal_math.future_value(
                req.current_amount,
                req.monthly_contribution,
                req.expected_return_rate,
                months,
            )
            on_track = projected >= req.target_amount

        return SimulateResponse(
            target_amount=req.target_amount,
            months=months,
            required_monthly=round(required, 2),
            projected_value=round(projected, 2) if projected is not None else None,
            on_track=on_track,
            insight=self._simulate_insight(req, months, required, projected, on_track),
        )

    # ── helpers ──────────────────────────────────────────────────
    async def _require(self, user: User, goal_id: str) -> Goal:
        goal = await self._goals.get(user.id, goal_id)
        if goal is None:
            raise NotFoundError("Goal not found.")
        return goal

    @staticmethod
    def _project(g: Goal) -> GoalOut:
        months = goal_math.months_between(date.today(), g.target_date)
        required = goal_math.required_monthly(
            g.target_amount, g.current_amount, g.expected_return_rate, months
        )
        projected = goal_math.future_value(
            g.current_amount, g.monthly_contribution, g.expected_return_rate, months
        )
        return GoalOut(
            id=g.id,
            name=g.name,
            category=g.category,
            target_amount=g.target_amount,
            current_amount=g.current_amount,
            target_date=g.target_date,
            monthly_contribution=g.monthly_contribution,
            expected_return_rate=g.expected_return_rate,
            progress_pct=round(g.current_amount / g.target_amount * 100, 1)
            if g.target_amount else 0.0,
            months_remaining=months,
            required_monthly=round(required, 2),
            projected_value=round(projected, 2),
            on_track=projected >= g.target_amount,
            surplus_or_shortfall=round(projected - g.target_amount, 2),
        )

    @staticmethod
    def _simulate_insight(
        req: SimulateRequest,
        months: int,
        required: float,
        projected: float | None,
        on_track: bool,
    ) -> ExplanationOut:
        years = months / 12
        summary = (
            f"To reach ₹{req.target_amount:,.0f} in {months} months "
            f"(~{years:.1f} years), invest about ₹{required:,.0f}/month."
        )
        reasons = [
            f"Assumes a {req.expected_return_rate:.0%} annual return on a starting "
            f"balance of ₹{req.current_amount:,.0f}.",
        ]
        risks = ["Returns aren't guaranteed; markets can underperform the assumption."]
        benefits: list[str] = []
        alternatives: list[str] = []
        if projected is not None:
            if on_track:
                benefits.append(
                    f"At ₹{req.monthly_contribution:,.0f}/month you're projected to reach "
                    f"₹{projected:,.0f} — on track."
                )
            else:
                alternatives.append(
                    f"₹{req.monthly_contribution:,.0f}/month projects to ₹{projected:,.0f} — "
                    f"increase to about ₹{required:,.0f} to stay on track."
                )
        return ExplanationOut(
            summary=summary,
            reasons=reasons,
            risks=risks,
            benefits=benefits,
            alternatives=alternatives,
            citations=["Time-value-of-money projection (SIP future value)."],
            confidence=0.8,
        )
