"""Pydantic schemas for the Notifications endpoints."""
from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel

from app.models.notification import NotificationCategory, NotificationPriority


class NotificationOut(BaseModel):
    id: str
    category: NotificationCategory
    title: str
    body: str
    priority: NotificationPriority
    created_at: datetime
    read: bool
    route: str | None = None


class NotificationsPageOut(BaseModel):
    items: list[NotificationOut]
    total: int
    unread_count: int


class UnreadCountOut(BaseModel):
    count: int


class MarkAllReadResponse(BaseModel):
    updated: int


class MessageResponse(BaseModel):
    message: str
