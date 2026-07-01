"""Analytics event repository + in-memory implementation.

Keeps a bounded ring of recent events in memory (newest-first) — enough to drive
the demo's usage summary without an external datastore. Production swaps this for
an append-only sink (Kafka/Kinesis → warehouse).
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from collections import deque

from app.models.analytics import AnalyticsEvent

_MAX_EVENTS = 5000


class AnalyticsRepository(ABC):
    @abstractmethod
    async def add(self, event: AnalyticsEvent) -> AnalyticsEvent: ...

    @abstractmethod
    async def all(self) -> list[AnalyticsEvent]: ...

    @abstractmethod
    async def count(self) -> int: ...


class InMemoryAnalyticsRepository(AnalyticsRepository):
    def __init__(self, max_events: int = _MAX_EVENTS) -> None:
        self._events: deque[AnalyticsEvent] = deque(maxlen=max_events)

    async def add(self, event: AnalyticsEvent) -> AnalyticsEvent:
        self._events.appendleft(event)
        return event

    async def all(self) -> list[AnalyticsEvent]:
        return list(self._events)

    async def count(self) -> int:
        return len(self._events)


_singleton = InMemoryAnalyticsRepository()


def get_analytics_repository() -> AnalyticsRepository:
    return _singleton
