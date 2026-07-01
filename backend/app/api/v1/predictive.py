"""Predictive Banking endpoints (`/api/v1/predictive`)."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends

from app.core.dependencies import CurrentUser
from app.repositories.account_repository import (
    AccountRepository,
    get_account_repository,
)
from app.repositories.spending_repository import (
    SpendingRepository,
    get_spending_repository,
)
from app.schemas.predictive import ForecastOut
from app.services.predictive_service import PredictiveService

router = APIRouter(prefix="/predictive", tags=["predictive"])


def get_predictive_service(
    accounts: Annotated[AccountRepository, Depends(get_account_repository)],
    spending: Annotated[SpendingRepository, Depends(get_spending_repository)],
) -> PredictiveService:
    return PredictiveService(accounts, spending)


PredictiveDep = Annotated[PredictiveService, Depends(get_predictive_service)]


@router.get(
    "/forecast",
    response_model=ForecastOut,
    summary="Cashflow forecast: salary, bills/EMIs, low-balance & tax predictions",
)
async def forecast(user: CurrentUser, service: PredictiveDep) -> ForecastOut:
    return await service.forecast(user)
