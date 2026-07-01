"""Goal repository abstraction + in-memory implementation.

Seeded with a few demo goals (anchored to the current date) so the planner shows
realistic progress. Module 20 swaps in a Postgres-backed implementation.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from datetime import date

from app.models.goal import Goal, GoalCategory
from app.services.goal_math import add_months

_DEMO_UID = "usr_demo_0001"


class GoalRepository(ABC):
    @abstractmethod
    async def list_for_user(self, user_id: str) -> list[Goal]: ...

    @abstractmethod
    async def get(self, user_id: str, goal_id: str) -> Goal | None: ...

    @abstractmethod
    async def create(self, goal: Goal) -> Goal: ...

    @abstractmethod
    async def update(self, goal: Goal) -> Goal: ...

    @abstractmethod
    async def delete(self, user_id: str, goal_id: str) -> bool: ...


class InMemoryGoalRepository(GoalRepository):
    def __init__(self) -> None:
        self._by_user: dict[str, dict[str, Goal]] = {}
        self._seed()

    def _seed(self) -> None:
        today = date.today()
        goals = [
            Goal(
                id="goal_emergency",
                user_id=_DEMO_UID,
                name="Emergency Fund",
                target_amount=600_000,
                current_amount=248_500,
                target_date=add_months(today, 12),
                monthly_contribution=15_000,
                expected_return_rate=0.06,
                category=GoalCategory.emergency,
            ),
            Goal(
                id="goal_vacation",
                user_id=_DEMO_UID,
                name="Dream Vacation",
                target_amount=300_000,
                current_amount=50_000,
                target_date=add_months(today, 18),
                monthly_contribution=8_000,
                expected_return_rate=0.08,
                category=GoalCategory.travel,
            ),
            Goal(
                id="goal_retirement",
                user_id=_DEMO_UID,
                name="Retirement Corpus",
                target_amount=20_000_000,
                current_amount=362_840,
                target_date=add_months(today, 300),  # 25 years
                monthly_contribution=25_000,
                expected_return_rate=0.11,
                category=GoalCategory.retirement,
            ),
        ]
        self._by_user[_DEMO_UID] = {g.id: g for g in goals}

    async def list_for_user(self, user_id: str) -> list[Goal]:
        return sorted(
            self._by_user.get(user_id, {}).values(),
            key=lambda g: g.target_date,
        )

    async def get(self, user_id: str, goal_id: str) -> Goal | None:
        return self._by_user.get(user_id, {}).get(goal_id)

    async def create(self, goal: Goal) -> Goal:
        self._by_user.setdefault(goal.user_id, {})[goal.id] = goal
        return goal

    async def update(self, goal: Goal) -> Goal:
        self._by_user.setdefault(goal.user_id, {})[goal.id] = goal
        return goal

    async def delete(self, user_id: str, goal_id: str) -> bool:
        return self._by_user.get(user_id, {}).pop(goal_id, None) is not None


from typing import Annotated  # noqa: E402

from fastapi import Depends  # noqa: E402
from sqlalchemy.ext.asyncio import AsyncSession  # noqa: E402

from app.db.session import get_db  # noqa: E402


async def get_goal_repository(
    session: Annotated[AsyncSession, Depends(get_db)],
) -> GoalRepository:
    from app.db.repositories import SqlAlchemyGoalRepository

    return SqlAlchemyGoalRepository(session)
