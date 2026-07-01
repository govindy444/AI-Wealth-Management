"""Async engine, session factory, and the request-scoped DB dependency.

The engine is built from `settings.database_url`. In *sandbox* the schema is
(re)created on startup for zero-friction dev; in staging/production the schema is
owned by Alembic migrations and is never auto-dropped.
"""
from __future__ import annotations

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.pool import NullPool

from app.core.config import get_settings
from app.core.logging import get_logger
from app.db.base import Base

_settings = get_settings()
_log = get_logger("db")

# `check_same_thread` only applies to SQLite; harmless to pass conditionally.
_connect_args = (
    {"check_same_thread": False} if _settings.database_url.startswith("sqlite") else {}
)

# NullPool: don't hold pooled connections across event loops. This keeps a
# file-backed SQLite DB usable from the (sync) TestClient — which spins up a new
# loop per request — and from one-off init at startup, without cross-loop pool
# errors. Production Postgres can switch to a real pool via env if desired.
engine = create_async_engine(
    _settings.database_url,
    echo=False,
    future=True,
    poolclass=NullPool,
    connect_args=_connect_args,
)

SessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency yielding a request-scoped session (rolled back on error)."""
    async with SessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise


def is_sqlite() -> bool:
    return _settings.database_url.startswith("sqlite")


async def init_db() -> None:
    """Create tables and seed demo data.

    Sandbox + SQLite: drop & recreate for a clean, deterministic dev/test DB.
    Other environments: create-if-missing only (Alembic owns real migrations).
    """
    from app.db.seed import seed_demo_data

    async with engine.begin() as conn:
        if is_sqlite() and _settings.environment == "sandbox":
            await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)

    async with SessionLocal() as session:
        await seed_demo_data(session)
        await session.commit()
    _log.info("db_initialized", url=_settings.database_url.split("://", 1)[0])
