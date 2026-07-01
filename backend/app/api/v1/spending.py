"""Spending Analytics endpoints (`/api/v1/spending`)."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.core.dependencies import CurrentUser
from app.models.spending import SpendCategory
from app.repositories.spending_repository import (
    SpendingRepository,
    get_spending_repository,
)
from app.schemas.spending import (
    BudgetOut,
    SetBudgetRequest,
    SpendingSummaryOut,
    TransactionsPageOut,
)
from app.services.spending_service import SpendingService

router = APIRouter(prefix="/spending", tags=["spending"])


def get_spending_service(
    repo: Annotated[SpendingRepository, Depends(get_spending_repository)],
) -> SpendingService:
    return SpendingService(repo)


SpendingDep = Annotated[SpendingService, Depends(get_spending_service)]

# Validated YYYY-MM query param → (year, month).
_MONTH = Annotated[str | None, Query(pattern=r"^\d{4}-\d{2}$")]


def _split_month(month: str | None) -> tuple[int | None, int | None]:
    if not month:
        return None, None
    y, m = month.split("-")
    return int(y), int(m)


@router.get(
    "/summary",
    response_model=SpendingSummaryOut,
    summary="Monthly spend summary: categories, trend, and an explainable insight",
)
async def summary(
    user: CurrentUser, service: SpendingDep, month: _MONTH = None
) -> SpendingSummaryOut:
    y, m = _split_month(month)
    return await service.summary(user.id, y, m)


@router.get(
    "/transactions",
    response_model=TransactionsPageOut,
    summary="Paginated, optionally category-filtered transactions for a month",
)
async def transactions(
    user: CurrentUser,
    service: SpendingDep,
    month: _MONTH = None,
    category: SpendCategory | None = None,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> TransactionsPageOut:
    y, m = _split_month(month)
    return await service.transactions(user.id, y, m, category, limit, offset)


@router.get(
    "/budgets",
    response_model=list[BudgetOut],
    summary="Category budgets with this month's progress",
)
async def budgets(
    user: CurrentUser, service: SpendingDep, month: _MONTH = None
) -> list[BudgetOut]:
    y, m = _split_month(month)
    return await service.budgets(user.id, y, m)


@router.put(
    "/budgets/{category}",
    response_model=BudgetOut,
    summary="Set or update a category's monthly budget",
)
async def set_budget(
    category: SpendCategory,
    req: SetBudgetRequest,
    user: CurrentUser,
    service: SpendingDep,
) -> BudgetOut:
    return await service.set_budget(user.id, category, req.monthly_limit)
