"""Reusable FastAPI dependencies for auth & RBAC."""
from __future__ import annotations

from typing import Annotated

from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer

from app.core.config import get_settings
from app.core.exceptions import ForbiddenError, UnauthorizedError
from app.models.user import User
from app.repositories.user_repository import UserRepository, get_user_repository
from app.services.auth_service import AuthService

_settings = get_settings()

# tokenUrl powers the Swagger "Authorize" button (OAuth2 password flow).
oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl=f"{_settings.api_v1_prefix}/auth/token", auto_error=False
)


def get_auth_service(
    users: Annotated[UserRepository, Depends(get_user_repository)],
) -> AuthService:
    return AuthService(users)


async def get_current_user(
    token: Annotated[str | None, Depends(oauth2_scheme)],
    service: Annotated[AuthService, Depends(get_auth_service)],
) -> User:
    if not token:
        raise UnauthorizedError("Authentication required.")
    return await service.current_user(token)


CurrentUser = Annotated[User, Depends(get_current_user)]


def require_roles(*roles: str):
    """Dependency factory enforcing that the current user has one of `roles`."""

    async def _checker(user: CurrentUser) -> User:
        if roles and not set(roles).intersection(user.roles):
            raise ForbiddenError("You do not have access to this resource.")
        return user

    return _checker
