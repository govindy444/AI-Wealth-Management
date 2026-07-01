"""Idempotent demo-data seeding for the persisted domains.

Mirrors what the old in-memory repositories seeded (demo user, profile, goals),
so the app and tests behave identically on the database.
"""
from __future__ import annotations

from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.db.base import GoalORM, ProfileORM, UserORM
from app.services.goal_math import add_months

_DEMO_UID = "usr_demo_0001"
_DEMO_EMAIL = "demo@idbi.example"


async def seed_demo_data(session: AsyncSession) -> None:
    existing = await session.scalar(select(UserORM).where(UserORM.id == _DEMO_UID))
    if existing is not None:
        return  # already seeded

    session.add(UserORM(
        id=_DEMO_UID,
        email=_DEMO_EMAIL,
        full_name="Demo User",
        hashed_password=hash_password("Password@123"),
        roles="customer",
        is_active=True,
    ))

    session.add(ProfileORM(
        user_id=_DEMO_UID,
        full_name="Demo User",
        email=_DEMO_EMAIL,
        phone="+91 90000 00000",
        kyc_status="verified",
        risk_profile="moderate",
        member_since=date(2023, 4, 12),
    ))

    today = date.today()
    goals = [
        ("goal_emergency", "Emergency Fund", 600_000, 248_500, 12, 15_000, 0.06, "emergency"),
        ("goal_vacation", "Dream Vacation", 300_000, 50_000, 18, 8_000, 0.08, "travel"),
        ("goal_retirement", "Retirement Corpus", 20_000_000, 362_840, 300, 25_000, 0.11, "retirement"),
    ]
    for gid, name, target, current, months, monthly, rate, cat in goals:
        session.add(GoalORM(
            id=gid,
            user_id=_DEMO_UID,
            name=name,
            target_amount=float(target),
            current_amount=float(current),
            target_date=add_months(today, months),
            monthly_contribution=float(monthly),
            expected_return_rate=rate,
            category=cat,
        ))
