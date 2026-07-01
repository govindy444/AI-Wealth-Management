"""Database layer: async SQLAlchemy engine, session, ORM models, and seeding.

Defaults to SQLite (`aiosqlite`) so the app runs with zero external services in
sandbox; production points `DATABASE_URL` at Postgres (`asyncpg`) and uses Alembic
for schema management.
"""
