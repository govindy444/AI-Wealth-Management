"""Portfolio Intelligence endpoints (`/api/v1/portfolio`)."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends

from app.core.dependencies import CurrentUser
from app.repositories.portfolio_repository import (
    PortfolioRepository,
    get_portfolio_repository,
)
from app.schemas.portfolio import HoldingOut, PortfolioSummaryOut
from app.services.portfolio_service import PortfolioService

router = APIRouter(prefix="/portfolio", tags=["portfolio"])


def get_portfolio_service(
    repo: Annotated[PortfolioRepository, Depends(get_portfolio_repository)],
) -> PortfolioService:
    return PortfolioService(repo)


PortfolioDep = Annotated[PortfolioService, Depends(get_portfolio_service)]


@router.get(
    "/summary",
    response_model=PortfolioSummaryOut,
    summary="Portfolio value, allocation, risk meter, and an explainable insight",
)
async def summary(user: CurrentUser, service: PortfolioDep) -> PortfolioSummaryOut:
    return await service.summary(user)


@router.get(
    "/holdings",
    response_model=list[HoldingOut],
    summary="Individual holdings with performance",
)
async def holdings(user: CurrentUser, service: PortfolioDep) -> list[HoldingOut]:
    return await service.list_holdings(user)
