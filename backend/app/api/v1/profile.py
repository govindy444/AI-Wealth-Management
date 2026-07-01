"""Profile & Settings endpoints (`/api/v1/profile`)."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends

from app.core.dependencies import CurrentUser
from app.repositories.profile_repository import (
    ProfileRepository,
    get_profile_repository,
)
from app.schemas.profile import (
    ProfileOut,
    UpdatePreferencesRequest,
    UpdateProfileRequest,
)
from app.services.profile_service import ProfileService

router = APIRouter(prefix="/profile", tags=["profile"])


def get_profile_service(
    repo: Annotated[ProfileRepository, Depends(get_profile_repository)],
) -> ProfileService:
    return ProfileService(repo)


ProfileDep = Annotated[ProfileService, Depends(get_profile_service)]


@router.get("", response_model=ProfileOut, summary="Current user's profile & preferences")
async def get_profile(user: CurrentUser, service: ProfileDep) -> ProfileOut:
    return await service.get_profile(user)


@router.patch("", response_model=ProfileOut, summary="Update profile fields")
async def update_profile(
    req: UpdateProfileRequest, user: CurrentUser, service: ProfileDep
) -> ProfileOut:
    return await service.update_profile(user, req)


@router.put(
    "/preferences",
    response_model=ProfileOut,
    summary="Update preferences (notifications, language, currency, consent)",
)
async def update_preferences(
    req: UpdatePreferencesRequest, user: CurrentUser, service: ProfileDep
) -> ProfileOut:
    return await service.update_preferences(user, req)
