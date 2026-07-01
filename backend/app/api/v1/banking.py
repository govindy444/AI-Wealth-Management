"""Banking & dashboard endpoints (`/api/v1/banking`)."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends

from app.core.dependencies import CurrentUser
from app.repositories.account_repository import (
    AccountRepository,
    get_account_repository,
)
from app.schemas.banking import DashboardResponse
from app.services.dashboard_service import DashboardService

router = APIRouter(prefix="/banking", tags=["banking"])


def get_dashboard_service(
    accounts: Annotated[AccountRepository, Depends(get_account_repository)],
) -> DashboardService:
    return DashboardService(accounts)


DashboardDep = Annotated[DashboardService, Depends(get_dashboard_service)]


@router.get(
    "/dashboard",
    response_model=DashboardResponse,
    summary="Net-worth summary, accounts, and an explainable AI insight",
)
async def dashboard(user: CurrentUser, service: DashboardDep) -> DashboardResponse:
    return await service.get_dashboard(user)
