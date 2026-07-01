"""Notification repository + in-memory implementation.

Seeded with a realistic cross-module notification feed for the demo user (the
first few unread). Module 20 swaps in a Postgres-backed store; Module 24 adds the
push-delivery pipeline.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from datetime import UTC, datetime, timedelta

from app.models.notification import (
    Notification,
    NotificationCategory,
    NotificationPriority,
)

_DEMO_UID = "usr_demo_0001"
_C = NotificationCategory
_P = NotificationPriority


class NotificationRepository(ABC):
    @abstractmethod
    async def list_for_user(
        self, user_id: str, unread_only: bool = False
    ) -> list[Notification]: ...

    @abstractmethod
    async def get(self, user_id: str, notification_id: str) -> Notification | None: ...

    @abstractmethod
    async def unread_count(self, user_id: str) -> int: ...

    @abstractmethod
    async def mark_read(self, user_id: str, notification_id: str) -> Notification | None: ...

    @abstractmethod
    async def mark_all_read(self, user_id: str) -> int: ...

    @abstractmethod
    async def delete(self, user_id: str, notification_id: str) -> bool: ...


class InMemoryNotificationRepository(NotificationRepository):
    def __init__(self) -> None:
        self._by_user: dict[str, list[Notification]] = {_DEMO_UID: self._seed()}

    @staticmethod
    def _seed() -> list[Notification]:
        now = datetime.now(UTC)

        def ago(hours: float) -> datetime:
            return now - timedelta(hours=hours)

        rows = [
            (_C.security, _P.high, "Unusual transaction flagged",
             "₹48,999 at QuickElectronics Online looks unusual — review it now.",
             0.5, False, "/fraud-alerts"),
            (_C.reminder, _P.high, "Home Loan EMI due soon",
             "Your EMI of ₹21,500 is due in 6 days.", 3, False, "/predictive"),
            (_C.alert, _P.normal, "Shopping budget exceeded",
             "You've used 102% of your shopping budget this month.", 8, False, "/spending"),
            (_C.goal, _P.normal, "Goal milestone reached",
             "Your Emergency Fund just crossed 40% — keep it up!", 26, True, "/goals"),
            (_C.insight, _P.normal, "Your net worth grew",
             "Net worth is up ₹7,710 this month.", 30, True, "/dashboard"),
            (_C.reminder, _P.normal, "Salary expected",
             "Your salary is expected to land in 2 days.", 34, True, "/predictive"),
            (_C.promo, _P.low, "New: AI Voice Assistant",
             "You can now ask your money questions by voice.", 50, True, "/voice"),
        ]
        return [
            Notification(
                id=f"ntf_{i:03d}",
                user_id=_DEMO_UID,
                category=cat,
                title=title,
                body=body,
                priority=prio,
                created_at=ago(hours),
                read=read,
                route=route,
            )
            for i, (cat, prio, title, body, hours, read, route) in enumerate(rows)
        ]

    def _items(self, user_id: str) -> list[Notification]:
        return self._by_user.setdefault(user_id, [])

    async def list_for_user(
        self, user_id: str, unread_only: bool = False
    ) -> list[Notification]:
        items = self._items(user_id)
        if unread_only:
            items = [n for n in items if not n.read]
        return sorted(items, key=lambda n: n.created_at, reverse=True)

    async def get(self, user_id: str, notification_id: str) -> Notification | None:
        return next((n for n in self._items(user_id) if n.id == notification_id), None)

    async def unread_count(self, user_id: str) -> int:
        return sum(1 for n in self._items(user_id) if not n.read)

    async def mark_read(self, user_id: str, notification_id: str) -> Notification | None:
        n = await self.get(user_id, notification_id)
        if n is not None:
            n.read = True
        return n

    async def mark_all_read(self, user_id: str) -> int:
        count = 0
        for n in self._items(user_id):
            if not n.read:
                n.read = True
                count += 1
        return count

    async def delete(self, user_id: str, notification_id: str) -> bool:
        items = self._items(user_id)
        for i, n in enumerate(items):
            if n.id == notification_id:
                items.pop(i)
                return True
        return False


_singleton = InMemoryNotificationRepository()


def get_notification_repository() -> NotificationRepository:
    return _singleton
