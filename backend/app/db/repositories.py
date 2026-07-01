"""SQLAlchemy-backed repository implementations for the persisted domains.

Each maps the ORM row ↔ the domain dataclass so the service layer is unchanged.
Writes commit on the request-scoped session.
"""
from __future__ import annotations

import uuid

from sqlalchemy import delete as sql_delete
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import GoalORM, ProfileORM, UserORM
from app.models.goal import Goal, GoalCategory
from app.models.investment import RiskProfile
from app.models.profile import KycStatus, UserPreferences, UserProfile
from app.models.user import User
from app.repositories.goal_repository import GoalRepository
from app.repositories.profile_repository import ProfileRepository
from app.repositories.user_repository import UserRepository


# ── users ────────────────────────────────────────────────────────
class SqlAlchemyUserRepository(UserRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    @staticmethod
    def _to_domain(row: UserORM) -> User:
        return User(
            id=row.id,
            email=row.email,
            full_name=row.full_name,
            hashed_password=row.hashed_password,
            roles=[r for r in row.roles.split(",") if r],
            is_active=row.is_active,
        )

    async def get_by_email(self, email: str) -> User | None:
        row = await self._s.scalar(
            select(UserORM).where(UserORM.email == email.lower())
        )
        return self._to_domain(row) if row else None

    async def get_by_id(self, user_id: str) -> User | None:
        row = await self._s.get(UserORM, user_id)
        return self._to_domain(row) if row else None

    async def create(self, user: User) -> User:
        if not user.id:
            user.id = f"usr_{uuid.uuid4().hex[:12]}"
        self._s.add(UserORM(
            id=user.id,
            email=user.email.lower(),
            full_name=user.full_name,
            hashed_password=user.hashed_password,
            roles=",".join(user.roles),
            is_active=user.is_active,
        ))
        await self._s.commit()
        return user


# ── profiles ─────────────────────────────────────────────────────
class SqlAlchemyProfileRepository(ProfileRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    @staticmethod
    def _to_domain(row: ProfileORM) -> UserProfile:
        return UserProfile(
            user_id=row.user_id,
            full_name=row.full_name,
            email=row.email,
            kyc_status=KycStatus(row.kyc_status),
            risk_profile=RiskProfile(row.risk_profile),
            member_since=row.member_since,
            phone=row.phone,
            preferences=UserPreferences(
                notifications_enabled=row.notifications_enabled,
                marketing_enabled=row.marketing_enabled,
                preferred_language=row.preferred_language,
                preferred_currency=row.preferred_currency,
                data_consent=row.data_consent,
            ),
        )

    async def get(self, user_id: str) -> UserProfile | None:
        row = await self._s.get(ProfileORM, user_id)
        return self._to_domain(row) if row else None

    async def upsert(self, profile: UserProfile) -> UserProfile:
        row = await self._s.get(ProfileORM, profile.user_id)
        p = profile.preferences
        if row is None:
            row = ProfileORM(user_id=profile.user_id)
            self._s.add(row)
        row.full_name = profile.full_name
        row.email = profile.email
        row.phone = profile.phone
        row.kyc_status = profile.kyc_status.value
        row.risk_profile = profile.risk_profile.value
        row.member_since = profile.member_since
        row.notifications_enabled = p.notifications_enabled
        row.marketing_enabled = p.marketing_enabled
        row.preferred_language = p.preferred_language
        row.preferred_currency = p.preferred_currency
        row.data_consent = p.data_consent
        await self._s.commit()
        return profile


# ── goals ────────────────────────────────────────────────────────
class SqlAlchemyGoalRepository(GoalRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    @staticmethod
    def _to_domain(row: GoalORM) -> Goal:
        return Goal(
            user_id=row.user_id,
            name=row.name,
            target_amount=row.target_amount,
            target_date=row.target_date,
            id=row.id,
            current_amount=row.current_amount,
            monthly_contribution=row.monthly_contribution,
            expected_return_rate=row.expected_return_rate,
            category=GoalCategory(row.category),
            created_at=row.created_at,
        )

    @staticmethod
    def _apply(row: GoalORM, goal: Goal) -> None:
        row.user_id = goal.user_id
        row.name = goal.name
        row.target_amount = goal.target_amount
        row.current_amount = goal.current_amount
        row.target_date = goal.target_date
        row.monthly_contribution = goal.monthly_contribution
        row.expected_return_rate = goal.expected_return_rate
        row.category = goal.category.value

    async def list_for_user(self, user_id: str) -> list[Goal]:
        rows = await self._s.scalars(
            select(GoalORM).where(GoalORM.user_id == user_id).order_by(GoalORM.target_date)
        )
        return [self._to_domain(r) for r in rows]

    async def get(self, user_id: str, goal_id: str) -> Goal | None:
        row = await self._s.get(GoalORM, goal_id)
        return self._to_domain(row) if (row and row.user_id == user_id) else None

    async def create(self, goal: Goal) -> Goal:
        row = GoalORM(id=goal.id, created_at=goal.created_at)
        self._apply(row, goal)
        self._s.add(row)
        await self._s.commit()
        return goal

    async def update(self, goal: Goal) -> Goal:
        row = await self._s.get(GoalORM, goal.id)
        if row is None:
            return await self.create(goal)
        self._apply(row, goal)
        await self._s.commit()
        return goal

    async def delete(self, user_id: str, goal_id: str) -> bool:
        row = await self._s.get(GoalORM, goal_id)
        if row is None or row.user_id != user_id:
            return False
        await self._s.execute(sql_delete(GoalORM).where(GoalORM.id == goal_id))
        await self._s.commit()
        return True
