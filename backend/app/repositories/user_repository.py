"""User repository abstraction + in-memory implementation.

The in-memory store is seeded with a demo user so the auth flow works end-to-end
before the database lands (Module 20). Services depend on [UserRepository], so the
Postgres-backed implementation can be dropped in without touching business logic.
"""
from __future__ import annotations

import uuid
from abc import ABC, abstractmethod

from app.core.security import hash_password
from app.models.user import User


class UserRepository(ABC):
    @abstractmethod
    async def get_by_email(self, email: str) -> User | None: ...

    @abstractmethod
    async def get_by_id(self, user_id: str) -> User | None: ...

    @abstractmethod
    async def create(self, user: User) -> User: ...


class InMemoryUserRepository(UserRepository):
    def __init__(self) -> None:
        self._by_id: dict[str, User] = {}
        self._by_email: dict[str, User] = {}
        self._seed_demo_user()

    def _seed_demo_user(self) -> None:
        demo = User(
            id="usr_demo_0001",
            email="demo@idbi.example",
            full_name="Demo User",
            hashed_password=hash_password("Password@123"),
            roles=["customer"],
        )
        self._by_id[demo.id] = demo
        self._by_email[demo.email.lower()] = demo

    async def get_by_email(self, email: str) -> User | None:
        return self._by_email.get(email.lower())

    async def get_by_id(self, user_id: str) -> User | None:
        return self._by_id.get(user_id)

    async def create(self, user: User) -> User:
        if not user.id:
            user.id = f"usr_{uuid.uuid4().hex[:12]}"
        self._by_id[user.id] = user
        self._by_email[user.email.lower()] = user
        return user


from typing import Annotated  # noqa: E402

from fastapi import Depends  # noqa: E402
from sqlalchemy.ext.asyncio import AsyncSession  # noqa: E402

from app.db.session import get_db  # noqa: E402


async def get_user_repository(
    session: Annotated[AsyncSession, Depends(get_db)],
) -> UserRepository:
    from app.db.repositories import SqlAlchemyUserRepository

    return SqlAlchemyUserRepository(session)
