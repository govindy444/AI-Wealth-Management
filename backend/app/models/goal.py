"""Goal Planner domain model.

Lightweight dataclass for the in-memory phase. Projections (required SIP,
projected value, on-track) are computed by the service via goal_math, not stored.
"""
from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from datetime import UTC, date, datetime
from enum import Enum


class GoalCategory(str, Enum):
    emergency = "emergency"
    travel = "travel"
    retirement = "retirement"
    home = "home"
    car = "car"
    education = "education"
    wealth = "wealth"
    other = "other"


@dataclass
class Goal:
    user_id: str
    name: str
    target_amount: float
    target_date: date
    id: str = field(default_factory=lambda: f"goal_{uuid.uuid4().hex[:12]}")
    current_amount: float = 0.0
    monthly_contribution: float = 0.0
    expected_return_rate: float = 0.10  # annual, decimal
    category: GoalCategory = GoalCategory.other
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))
