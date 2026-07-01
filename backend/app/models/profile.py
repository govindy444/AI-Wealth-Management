"""User profile & preferences domain model.

Extends the auth `User` with display/KYC info and editable preferences.
Lightweight dataclasses for the in-memory phase; Module 20 moves these to the DB.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from enum import Enum

from app.models.investment import RiskProfile


class KycStatus(str, Enum):
    not_started = "not_started"
    pending = "pending"
    verified = "verified"


@dataclass
class UserPreferences:
    notifications_enabled: bool = True
    marketing_enabled: bool = False
    preferred_language: str = "en"     # ISO-639-1
    preferred_currency: str = "INR"
    # Consent to let the AI analyse the customer's financial data.
    data_consent: bool = True


@dataclass
class UserProfile:
    user_id: str
    full_name: str
    email: str
    kyc_status: KycStatus = KycStatus.verified
    risk_profile: RiskProfile = RiskProfile.moderate
    member_since: date = field(default_factory=lambda: date(2023, 1, 1))
    phone: str | None = None
    preferences: UserPreferences = field(default_factory=UserPreferences)
