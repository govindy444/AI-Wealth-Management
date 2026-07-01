"""Pydantic schemas for the product-analytics endpoints."""
from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class AnalyticsEventIn(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    feature: str = Field(min_length=1, max_length=60)
    properties: dict[str, Any] = Field(default_factory=dict)


class AnalyticsEventOut(BaseModel):
    id: str
    name: str
    feature: str
    created_at: datetime


class FeatureUsageOut(BaseModel):
    feature: str
    count: int


class EventCountOut(BaseModel):
    name: str
    count: int


class AnalyticsSummaryOut(BaseModel):
    total_events: int
    unique_features: int
    by_feature: list[FeatureUsageOut]
    top_events: list[EventCountOut]
    last_event_at: datetime | None = None
