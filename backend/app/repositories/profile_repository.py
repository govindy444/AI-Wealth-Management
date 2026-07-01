"""Profile repository + in-memory implementation.

Seeds the demo user's profile; for any other (e.g. newly registered) user a
default profile is created lazily from their auth record. Module 20 swaps in a
Postgres-backed store.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from datetime import date

from app.models.investment import RiskProfile
from app.models.profile import KycStatus, UserPreferences, UserProfile

_DEMO_UID = "usr_demo_0001"


class ProfileRepository(ABC):
    @abstractmethod
    async def get(self, user_id: str) -> UserProfile | None: ...

    @abstractmethod
    async def upsert(self, profile: UserProfile) -> UserProfile: ...


class InMemoryProfileRepository(ProfileRepository):
    def __init__(self) -> None:
        self._by_user: dict[str, UserProfile] = {
            _DEMO_UID: UserProfile(
                user_id=_DEMO_UID,
                full_name="Demo User",
                email="demo@idbi.example",
                kyc_status=KycStatus.verified,
                risk_profile=RiskProfile.moderate,
                member_since=date(2023, 4, 12),
                phone="+91 90000 00000",
                preferences=UserPreferences(),
            )
        }

    async def get(self, user_id: str) -> UserProfile | None:
        return self._by_user.get(user_id)

    async def upsert(self, profile: UserProfile) -> UserProfile:
        self._by_user[profile.user_id] = profile
        return profile


from typing import Annotated  # noqa: E402

from fastapi import Depends  # noqa: E402
from sqlalchemy.ext.asyncio import AsyncSession  # noqa: E402

from app.db.session import get_db  # noqa: E402


async def get_profile_repository(
    session: Annotated[AsyncSession, Depends(get_db)],
) -> ProfileRepository:
    from app.db.repositories import SqlAlchemyProfileRepository

    return SqlAlchemyProfileRepository(session)
