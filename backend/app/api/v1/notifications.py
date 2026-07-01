"""Notifications endpoints (`/api/v1/notifications`)."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.core.dependencies import CurrentUser
from app.repositories.notification_repository import (
    NotificationRepository,
    get_notification_repository,
)
from app.schemas.notifications import (
    MarkAllReadResponse,
    MessageResponse,
    NotificationOut,
    NotificationsPageOut,
    UnreadCountOut,
)
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["notifications"])


def get_notification_service(
    repo: Annotated[NotificationRepository, Depends(get_notification_repository)],
) -> NotificationService:
    return NotificationService(repo)


NotifDep = Annotated[NotificationService, Depends(get_notification_service)]


@router.get("", response_model=NotificationsPageOut, summary="List notifications")
async def list_notifications(
    user: CurrentUser,
    service: NotifDep,
    unread_only: bool = False,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> NotificationsPageOut:
    return await service.list_notifications(user, unread_only, limit, offset)


@router.get(
    "/unread-count", response_model=UnreadCountOut, summary="Unread badge count"
)
async def unread_count(user: CurrentUser, service: NotifDep) -> UnreadCountOut:
    return UnreadCountOut(count=await service.unread_count(user))


@router.post(
    "/read-all", response_model=MarkAllReadResponse, summary="Mark all as read"
)
async def mark_all_read(user: CurrentUser, service: NotifDep) -> MarkAllReadResponse:
    return MarkAllReadResponse(updated=await service.mark_all_read(user))


@router.post(
    "/{notification_id}/read",
    response_model=NotificationOut,
    summary="Mark one as read",
)
async def mark_read(
    notification_id: str, user: CurrentUser, service: NotifDep
) -> NotificationOut:
    return await service.mark_read(user, notification_id)


@router.delete(
    "/{notification_id}", response_model=MessageResponse, summary="Delete a notification"
)
async def delete_notification(
    notification_id: str, user: CurrentUser, service: NotifDep
) -> MessageResponse:
    await service.delete(user, notification_id)
    return MessageResponse(message="Notification deleted.")
