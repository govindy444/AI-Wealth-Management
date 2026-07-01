"""AI Avatar endpoints (`/api/v1/avatar`)."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends

from app.core.dependencies import CurrentUser
from app.repositories.avatar_repository import AvatarRepository, get_avatar_repository
from app.schemas.avatar import (
    AvatarPresentationOut,
    PersonaOut,
    PresentRequest,
)
from app.services.avatar_presenter import RuleBasedAvatarPresenter
from app.services.avatar_service import AvatarService

router = APIRouter(prefix="/avatar", tags=["avatar"])


def get_avatar_service(
    personas: Annotated[AvatarRepository, Depends(get_avatar_repository)],
) -> AvatarService:
    return AvatarService(personas, RuleBasedAvatarPresenter())


AvatarDep = Annotated[AvatarService, Depends(get_avatar_service)]


@router.get(
    "/personas",
    response_model=list[PersonaOut],
    summary="List available avatar personas and their languages",
)
async def list_personas(user: CurrentUser, service: AvatarDep) -> list[PersonaOut]:
    return await service.list_personas()


@router.post(
    "/present",
    response_model=AvatarPresentationOut,
    summary="Turn text into an avatar performance (expression + timed segments)",
)
async def present(
    req: PresentRequest, user: CurrentUser, service: AvatarDep
) -> AvatarPresentationOut:
    return await service.present(req.text, req.persona_id, req.language)
