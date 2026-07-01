"""Product-analytics event model.

Captures lightweight feature-usage events reported by the SDK / demo app
(e.g. "viewed_dashboard", "asked_advisor", "simulated_goal") so the bank can see
which AI features customers actually engage with. Lightweight dataclass for the
in-memory phase; a production deployment streams these to a warehouse.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any


@dataclass
class AnalyticsEvent:
    id: str
    user_id: str
    name: str                       # event name, e.g. "viewed_dashboard"
    feature: str                    # owning feature, e.g. "dashboard"
    created_at: datetime
    properties: dict[str, Any] = field(default_factory=dict)
