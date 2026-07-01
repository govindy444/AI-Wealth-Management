"""Tests for the SQLAlchemy persistence layer (Module 20).

These assert that the migrated domains (users, profiles, goals) are genuinely
backed by the database — not in-memory — and persist across requests.
"""
import sqlite3

from fastapi.testclient import TestClient

from app.db.session import engine
from app.main import app

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def test_engine_is_configured() -> None:
    # Sandbox default is SQLite; production overrides DATABASE_URL to Postgres.
    assert "sqlite" in str(engine.url)


def test_demo_user_row_exists_in_sqlite_file() -> None:
    # The app seeds into a real on-disk SQLite database, proving it's not in-memory.
    conn = sqlite3.connect("wealth_ai.db")
    try:
        row = conn.execute(
            "SELECT email, full_name FROM users WHERE id = ?", ("usr_demo_0001",)
        ).fetchone()
    finally:
        conn.close()
    assert row is not None
    assert row[0] == "demo@idbi.example"


def test_seeded_goals_are_persisted() -> None:
    goals = client.get("/api/v1/goals", headers=_auth_headers()).json()
    names = {g["name"] for g in goals}
    assert {"Emergency Fund", "Dream Vacation", "Retirement Corpus"}.issubset(names)


def test_created_goal_persists_across_requests() -> None:
    headers = _auth_headers()
    created = client.post(
        "/api/v1/goals",
        json={
            "name": "DB Persistence Goal",
            "target_amount": 250000,
            "target_date": "2030-01-01",
            "current_amount": 10000,
            "monthly_contribution": 4000,
        },
        headers=headers,
    )
    assert created.status_code == 201
    goal_id = created.json()["id"]

    # A *separate* request → a fresh DB session. If it round-trips, it persisted.
    fetched = client.get(f"/api/v1/goals/{goal_id}", headers=headers)
    assert fetched.status_code == 200
    assert fetched.json()["name"] == "DB Persistence Goal"

    # And it's a real row in the SQLite file.
    conn = sqlite3.connect("wealth_ai.db")
    try:
        row = conn.execute(
            "SELECT name FROM goals WHERE id = ?", (goal_id,)
        ).fetchone()
    finally:
        conn.close()
    assert row is not None and row[0] == "DB Persistence Goal"


def test_profile_update_persists_to_db() -> None:
    headers = _auth_headers()
    client.put(
        "/api/v1/profile/preferences",
        json={"data_consent": False},
        headers=headers,
    )
    conn = sqlite3.connect("wealth_ai.db")
    try:
        row = conn.execute(
            "SELECT data_consent FROM profiles WHERE user_id = ?", ("usr_demo_0001",)
        ).fetchone()
    finally:
        conn.close()
    assert row is not None and row[0] == 0  # False stored as 0
