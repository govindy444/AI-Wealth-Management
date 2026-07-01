"""Authentication & session endpoints (`/api/v1/auth`)."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from fastapi.security import OAuth2PasswordRequestForm

from app.core.dependencies import CurrentUser, get_auth_service
from app.schemas.auth import (
    LoginRequest,
    MessageResponse,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
    UserOut,
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])

AuthDep = Annotated[AuthService, Depends(get_auth_service)]


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new customer and start a session",
)
async def register(req: RegisterRequest, service: AuthDep) -> TokenResponse:
    return await service.register(req)


@router.post("/login", response_model=TokenResponse, summary="Login with email + password")
async def login(req: LoginRequest, service: AuthDep) -> TokenResponse:
    return await service.login(req)


@router.post(
    "/token",
    response_model=TokenResponse,
    summary="OAuth2 password-grant token (used by Swagger Authorize)",
)
async def token(
    form: Annotated[OAuth2PasswordRequestForm, Depends()],
    service: AuthDep,
) -> TokenResponse:
    # OAuth2 spec uses `username`; we treat it as the email.
    return await service.login(LoginRequest(email=form.username, password=form.password))


@router.post("/refresh", response_model=TokenResponse, summary="Exchange a refresh token")
async def refresh(req: RefreshRequest, service: AuthDep) -> TokenResponse:
    return await service.refresh(req.refresh_token)


@router.get("/me", response_model=UserOut, summary="Current authenticated user")
async def me(user: CurrentUser) -> UserOut:
    return UserOut(id=user.id, email=user.email, full_name=user.full_name, roles=user.roles)


@router.post("/logout", response_model=MessageResponse, summary="Logout (client clears tokens)")
async def logout(user: CurrentUser) -> MessageResponse:
    return MessageResponse(message="Logged out.")
