"""Declarative base + ORM models for persisted domains.

Only the *system-of-record write* domains live here (users, profiles, goals).
Read-only reference/feed domains (accounts, transactions, the product catalog,
portfolio holdings) come from the bank's core systems in production and remain
behind their repository abstractions.
"""
from __future__ import annotations

from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Float, String, Text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class UserORM(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    full_name: Mapped[str] = mapped_column(String(120))
    hashed_password: Mapped[str] = mapped_column(String(255))
    roles: Mapped[str] = mapped_column(String(255), default="customer")  # CSV
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class ProfileORM(Base):
    __tablename__ = "profiles"

    user_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    full_name: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(255))
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    kyc_status: Mapped[str] = mapped_column(String(20), default="verified")
    risk_profile: Mapped[str] = mapped_column(String(20), default="moderate")
    member_since: Mapped[date] = mapped_column(Date, default=date(2023, 1, 1))
    notifications_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    marketing_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    preferred_language: Mapped[str] = mapped_column(String(5), default="en")
    preferred_currency: Mapped[str] = mapped_column(String(3), default="INR")
    data_consent: Mapped[bool] = mapped_column(Boolean, default=True)


class GoalORM(Base):
    __tablename__ = "goals"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(64), index=True)
    name: Mapped[str] = mapped_column(String(120))
    target_amount: Mapped[float] = mapped_column(Float)
    current_amount: Mapped[float] = mapped_column(Float, default=0.0)
    target_date: Mapped[date] = mapped_column(Date)
    monthly_contribution: Mapped[float] = mapped_column(Float, default=0.0)
    expected_return_rate: Mapped[float] = mapped_column(Float, default=0.10)
    category: Mapped[str] = mapped_column(String(20), default="other")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
