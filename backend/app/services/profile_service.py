"""Profile & Settings business logic.

Reads/updates the user's profile and preferences. For a user without a stored
profile (e.g. just registered), a sensible default is created from their auth
record on first access.
"""
from __future__ import annotations

from app.models.profile import UserPreferences, UserProfile
from app.models.user import User
from app.repositories.profile_repository import ProfileRepository
from app.schemas.profile import (
    PreferencesOut,
    ProfileOut,
    UpdatePreferencesRequest,
    UpdateProfileRequest,
)


class ProfileService:
    def __init__(self, repo: ProfileRepository) -> None:
        self._repo = repo

    async def get_profile(self, user: User) -> ProfileOut:
        return self._to_out(await self._resolve(user))

    async def update_profile(self, user: User, req: UpdateProfileRequest) -> ProfileOut:
        profile = await self._resolve(user)
        if req.full_name is not None:
            profile.full_name = req.full_name
        if req.phone is not None:
            profile.phone = req.phone
        if req.risk_profile is not None:
            profile.risk_profile = req.risk_profile
        return self._to_out(await self._repo.upsert(profile))

    async def update_preferences(
        self, user: User, req: UpdatePreferencesRequest
    ) -> ProfileOut:
        profile = await self._resolve(user)
        p = profile.preferences
        if req.notifications_enabled is not None:
            p.notifications_enabled = req.notifications_enabled
        if req.marketing_enabled is not None:
            p.marketing_enabled = req.marketing_enabled
        if req.preferred_language is not None:
            p.preferred_language = req.preferred_language
        if req.preferred_currency is not None:
            p.preferred_currency = req.preferred_currency.upper()
        if req.data_consent is not None:
            p.data_consent = req.data_consent
        return self._to_out(await self._repo.upsert(profile))

    async def _resolve(self, user: User) -> UserProfile:
        profile = await self._repo.get(user.id)
        if profile is None:
            profile = UserProfile(
                user_id=user.id,
                full_name=user.full_name,
                email=user.email,
                preferences=UserPreferences(),
            )
            await self._repo.upsert(profile)
        return profile

    @staticmethod
    def _to_out(p: UserProfile) -> ProfileOut:
        return ProfileOut(
            user_id=p.user_id,
            full_name=p.full_name,
            email=p.email,
            phone=p.phone,
            kyc_status=p.kyc_status,
            risk_profile=p.risk_profile,
            member_since=p.member_since,
            preferences=PreferencesOut(
                notifications_enabled=p.preferences.notifications_enabled,
                marketing_enabled=p.preferences.marketing_enabled,
                preferred_language=p.preferences.preferred_language,
                preferred_currency=p.preferences.preferred_currency,
                data_consent=p.preferences.data_consent,
            ),
        )
