"""Financial Health Engine endpoints (`/api/v1/financial-health`).

Distinct from the system `/health` liveness check — this is the user's financial
wellness score.
"""
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
from app.schemas.financial_health import FinancialHealthOut
from app.services.financial_health_service import FinancialHealthService
from app.services.spending_service import SpendingService

router = APIRouter(prefix="/financial-health", tags=["financial-health"])


def get_financial_health_service(
    accounts: Annotated[AccountRepository, Depends(get_account_repository)],
    spending_repo: Annotated[SpendingRepository, Depends(get_spending_repository)],
) -> FinancialHealthService:
    return FinancialHealthService(accounts, SpendingService(spending_repo))


HealthDep = Annotated[FinancialHealthService, Depends(get_financial_health_service)]


@router.get(
    "/score",
    response_model=FinancialHealthOut,
    summary="Overall financial-health score with explainable pillars",
)
async def score(user: CurrentUser, service: HealthDep) -> FinancialHealthOut:
    return await service.score(user)
