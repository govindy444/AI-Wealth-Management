"""Notification business logic: list, unread count, mark read, delete."""
from __future__ import annotations

from app.core.exceptions import NotFoundError
from app.models.notification import Notification
from app.models.user import User
from app.repositories.notification_repository import NotificationRepository
from app.schemas.notifications import (
    NotificationOut,
    NotificationsPageOut,
)


class NotificationService:
    def __init__(self, repo: NotificationRepository) -> None:
        self._repo = repo

    async def list_notifications(
        self, user: User, unread_only: bool, limit: int, offset: int
    ) -> NotificationsPageOut:
        items = await self._repo.list_for_user(user.id, unread_only=unread_only)
        unread = await self._repo.unread_count(user.id)
        page = items[offset : offset + limit]
        return NotificationsPageOut(
            items=[self._to_out(n) for n in page],
            total=len(items),
            unread_count=unread,
        )

    async def unread_count(self, user: User) -> int:
        return await self._repo.unread_count(user.id)

    async def mark_read(self, user: User, notification_id: str) -> NotificationOut:
        n = await self._repo.mark_read(user.id, notification_id)
        if n is None:
            raise NotFoundError("Notification not found.")
        return self._to_out(n)

    async def mark_all_read(self, user: User) -> int:
        return await self._repo.mark_all_read(user.id)

    async def delete(self, user: User, notification_id: str) -> None:
        if not await self._repo.delete(user.id, notification_id):
            raise NotFoundError("Notification not found.")

    @staticmethod
    def _to_out(n: Notification) -> NotificationOut:
        return NotificationOut(
            id=n.id,
            category=n.category,
            title=n.title,
            body=n.body,
            priority=n.priority,
            created_at=n.created_at,
            read=n.read,
            route=n.route,
        )
