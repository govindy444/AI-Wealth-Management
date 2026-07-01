"""Fraud Detection endpoints (`/api/v1/fraud`)."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends

from app.core.dependencies import CurrentUser
from app.repositories.fraud_repository import FraudRepository, get_fraud_repository
from app.schemas.fraud import (
    CheckMessageRequest,
    CheckMessageResponse,
    FraudAlertsOut,
)
from app.services.fraud_service import FraudService

router = APIRouter(prefix="/fraud", tags=["fraud"])


def get_fraud_service(
    repo: Annotated[FraudRepository, Depends(get_fraud_repository)],
) -> FraudService:
    return FraudService(repo)


FraudDep = Annotated[FraudService, Depends(get_fraud_service)]


@router.get(
    "/alerts",
    response_model=FraudAlertsOut,
    summary="Anomaly alerts detected in recent activity",
)
async def alerts(user: CurrentUser, service: FraudDep) -> FraudAlertsOut:
    return await service.alerts(user)


@router.post(
    "/check-message",
    response_model=CheckMessageResponse,
    summary="Score an SMS/email for scam/phishing risk",
)
async def check_message(
    req: CheckMessageRequest, user: CurrentUser, service: FraudDep
) -> CheckMessageResponse:
    return service.check_message(req.text)
