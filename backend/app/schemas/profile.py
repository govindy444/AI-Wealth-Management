"""Pydantic schemas for the Profile & Settings endpoints."""
from __future__ import annotations

from datetime import date

from pydantic import BaseModel, Field

from app.models.investment import RiskProfile
from app.models.profile import KycStatus


class PreferencesOut(BaseModel):
    notifications_enabled: bool
    marketing_enabled: bool
    preferred_language: str
    preferred_currency: str
    data_consent: bool


class ProfileOut(BaseModel):
    user_id: str
    full_name: str
    email: str
    phone: str | None
    kyc_status: KycStatus
    risk_profile: RiskProfile
    member_since: date
    preferences: PreferencesOut


class UpdateProfileRequest(BaseModel):
    full_name: str | None = Field(default=None, min_length=1, max_length=120)
    phone: str | None = Field(default=None, max_length=20)
    risk_profile: RiskProfile | None = None


class UpdatePreferencesRequest(BaseModel):
    notifications_enabled: bool | None = None
    marketing_enabled: bool | None = None
    preferred_language: str | None = Field(default=None, min_length=2, max_length=5)
    preferred_currency: str | None = Field(default=None, min_length=3, max_length=3)
    data_consent: bool | None = None
