"""Investment Recommendation endpoints (`/api/v1/recommendations`)."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends

from app.core.dependencies import CurrentUser
from app.repositories.investment_repository import (
    InvestmentRepository,
    get_investment_repository,
)
from app.schemas.recommendations import (
    InvestmentProductOut,
    RecommendationSetOut,
    RecommendRequest,
)
from app.services.recommendation_service import RecommendationService

router = APIRouter(prefix="/recommendations", tags=["recommendations"])


def get_recommendation_service(
    repo: Annotated[InvestmentRepository, Depends(get_investment_repository)],
) -> RecommendationService:
    return RecommendationService(repo)


RecoDep = Annotated[RecommendationService, Depends(get_recommendation_service)]


@router.get(
    "/products",
    response_model=list[InvestmentProductOut],
    summary="The available investment product shelf",
)
async def products(user: CurrentUser, service: RecoDep) -> list[InvestmentProductOut]:
    return await service.list_products()


@router.post(
    "",
    response_model=RecommendationSetOut,
    summary="Get an explainable, risk-matched portfolio recommendation",
)
async def recommend(
    req: RecommendRequest, user: CurrentUser, service: RecoDep
) -> RecommendationSetOut:
    return await service.recommend(req.risk_profile, req.amount, req.horizon_years)
