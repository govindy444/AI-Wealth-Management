"""Product-analytics endpoints (`/api/v1/analytics`).

The SDK / demo app POSTs feature-usage events here; the bank reads aggregated
usage from the summary endpoint. Both require authentication.
"""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status

from app.core.dependencies import CurrentUser
from app.repositories.analytics_repository import (
    AnalyticsRepository,
    get_analytics_repository,
)
from app.schemas.analytics import (
    AnalyticsEventIn,
    AnalyticsEventOut,
    AnalyticsSummaryOut,
)
from app.services.analytics_service import AnalyticsService

router = APIRouter(prefix="/analytics", tags=["analytics"])


def get_analytics_service(
    repo: Annotated[AnalyticsRepository, Depends(get_analytics_repository)],
) -> AnalyticsService:
    return AnalyticsService(repo)


AnalyticsDep = Annotated[AnalyticsService, Depends(get_analytics_service)]


@router.post(
    "/events",
    response_model=AnalyticsEventOut,
    status_code=status.HTTP_201_CREATED,
    summary="Record a feature-usage event",
)
async def record_event(
    body: AnalyticsEventIn, user: CurrentUser, service: AnalyticsDep
) -> AnalyticsEventOut:
    return await service.record(user, body)


@router.get(
    "/summary",
    response_model=AnalyticsSummaryOut,
    summary="Aggregated feature-usage summary",
)
async def usage_summary(user: CurrentUser, service: AnalyticsDep) -> AnalyticsSummaryOut:
    return await service.summary()
