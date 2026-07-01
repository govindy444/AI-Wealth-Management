"""Notification domain model.

A unified notification aggregates signals from across the platform (security,
spending, goals, predictions, insights). Lightweight dataclass for the in-memory
phase; Module 20 moves it to the database (and Module 24 wires real push).
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from enum import Enum


class NotificationCategory(str, Enum):
    security = "security"
    alert = "alert"
    reminder = "reminder"
    insight = "insight"
    goal = "goal"
    transaction = "transaction"
    promo = "promo"


class NotificationPriority(str, Enum):
    low = "low"
    normal = "normal"
    high = "high"


@dataclass
class Notification:
    id: str
    user_id: str
    category: NotificationCategory
    title: str
    body: str
    priority: NotificationPriority
    created_at: datetime
    read: bool = False
    # Optional in-app deep link (a host route the tap should open).
    route: str | None = None
