"""Authentication business logic: register, login, refresh, current-user lookup."""
from __future__ import annotations

from app.core.config import get_settings
from app.core.exceptions import (
    ConflictError,
    TooManyRequestsError,
    UnauthorizedError,
)
from app.core.login_throttle import get_login_throttler
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.auth import (
    LoginRequest,
    RegisterRequest,
    TokenResponse,
    UserOut,
)


class AuthService:
    def __init__(self, users: UserRepository) -> None:
        self._users = users

    # ── helpers ──────────────────────────────────
    @staticmethod
    def _to_user_out(user: User) -> UserOut:
        return UserOut(
            id=user.id, email=user.email, full_name=user.full_name, roles=user.roles
        )

    def _issue_tokens(self, user: User) -> TokenResponse:
        settings = get_settings()
        return TokenResponse(
            access_token=create_access_token(user.id, roles=user.roles),
            refresh_token=create_refresh_token(user.id),
            expires_in=settings.access_token_expire_minutes * 60,
            user=self._to_user_out(user),
        )

    # ── use cases ────────────────────────────────
    async def register(self, req: RegisterRequest) -> TokenResponse:
        existing = await self._users.get_by_email(req.email)
        if existing is not None:
            raise ConflictError("An account with this email already exists.")
        user = await self._users.create(
            User(
                id="",
                email=req.email,
                full_name=req.full_name,
                hashed_password=hash_password(req.password),
            )
        )
        return self._issue_tokens(user)

    async def login(self, req: LoginRequest) -> TokenResponse:
        throttler = get_login_throttler()
        if throttler.is_locked(req.email):
            raise TooManyRequestsError(
                "Too many failed login attempts. Please try again later."
            )

        user = await self._users.get_by_email(req.email)
        if user is None or not verify_password(req.password, user.hashed_password):
            throttler.record_failure(req.email)
            raise UnauthorizedError("Invalid email or password.")
        if not user.is_active:
            raise UnauthorizedError("This account is disabled.")

        throttler.reset(req.email)  # clear the failure counter on success
        return self._issue_tokens(user)

    async def refresh(self, refresh_token: str) -> TokenResponse:
        try:
            payload = decode_token(refresh_token, expected_type="refresh")
        except ValueError as exc:
            raise UnauthorizedError("Invalid or expired refresh token.") from exc
        user = await self._users.get_by_id(payload["sub"])
        if user is None or not user.is_active:
            raise UnauthorizedError("Session no longer valid.")
        return self._issue_tokens(user)

    async def current_user(self, access_token: str) -> User:
        try:
            payload = decode_token(access_token, expected_type="access")
        except ValueError as exc:
            raise UnauthorizedError("Invalid or expired access token.") from exc
        user = await self._users.get_by_id(payload["sub"])
        if user is None or not user.is_active:
            raise UnauthorizedError("User not found.")
        return user
