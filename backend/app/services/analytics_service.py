"""Product-analytics business logic: record events and summarize usage."""
from __future__ import annotations

import uuid
from collections import Counter
from datetime import UTC, datetime

from app.models.analytics import AnalyticsEvent
from app.models.user import User
from app.repositories.analytics_repository import AnalyticsRepository
from app.schemas.analytics import (
    AnalyticsEventIn,
    AnalyticsEventOut,
    AnalyticsSummaryOut,
    EventCountOut,
    FeatureUsageOut,
)


class AnalyticsService:
    def __init__(self, repo: AnalyticsRepository) -> None:
        self._repo = repo

    async def record(self, user: User, req: AnalyticsEventIn) -> AnalyticsEventOut:
        event = AnalyticsEvent(
            id=f"evt_{uuid.uuid4().hex[:12]}",
            user_id=user.id,
            name=req.name.strip(),
            feature=req.feature.strip().lower(),
            created_at=datetime.now(UTC),
            properties=req.properties,
        )
        await self._repo.add(event)
        return AnalyticsEventOut(
            id=event.id,
            name=event.name,
            feature=event.feature,
            created_at=event.created_at,
        )

    async def summary(self, *, top: int = 10) -> AnalyticsSummaryOut:
        events = await self._repo.all()
        feature_counter: Counter[str] = Counter(e.feature for e in events)
        event_counter: Counter[str] = Counter(e.name for e in events)
        last_event_at = max((e.created_at for e in events), default=None)
        return AnalyticsSummaryOut(
            total_events=len(events),
            unique_features=len(feature_counter),
            by_feature=[
                FeatureUsageOut(feature=f, count=c)
                for f, c in feature_counter.most_common()
            ],
            top_events=[
                EventCountOut(name=n, count=c)
                for n, c in event_counter.most_common(top)
            ],
            last_event_at=last_event_at,
        )
