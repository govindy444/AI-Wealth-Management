"""initial schema: users, profiles, goals

Revision ID: 0001_initial
Revises:
Create Date: 2026-06-30
"""
from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0001_initial"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("full_name", sa.String(120), nullable=False),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("roles", sa.String(255), nullable=False, server_default="customer"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "profiles",
        sa.Column("user_id", sa.String(64), primary_key=True),
        sa.Column("full_name", sa.String(120), nullable=False),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("phone", sa.String(20), nullable=True),
        sa.Column("kyc_status", sa.String(20), nullable=False, server_default="verified"),
        sa.Column("risk_profile", sa.String(20), nullable=False, server_default="moderate"),
        sa.Column("member_since", sa.Date(), nullable=False),
        sa.Column("notifications_enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("marketing_enabled", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("preferred_language", sa.String(5), nullable=False, server_default="en"),
        sa.Column("preferred_currency", sa.String(3), nullable=False, server_default="INR"),
        sa.Column("data_consent", sa.Boolean(), nullable=False, server_default=sa.true()),
    )

    op.create_table(
        "goals",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("user_id", sa.String(64), nullable=False),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("target_amount", sa.Float(), nullable=False),
        sa.Column("current_amount", sa.Float(), nullable=False, server_default="0"),
        sa.Column("target_date", sa.Date(), nullable=False),
        sa.Column("monthly_contribution", sa.Float(), nullable=False, server_default="0"),
        sa.Column("expected_return_rate", sa.Float(), nullable=False, server_default="0.1"),
        sa.Column("category", sa.String(20), nullable=False, server_default="other"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("note", sa.Text(), nullable=True),
    )
    op.create_index("ix_goals_user_id", "goals", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_goals_user_id", table_name="goals")
    op.drop_table("goals")
    op.drop_table("profiles")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")
