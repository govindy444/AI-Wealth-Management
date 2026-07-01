"""Pydantic schemas for the Voice Assistant endpoints."""
from __future__ import annotations

from pydantic import BaseModel, Field

from app.schemas.chat import MessageOut


class VoiceLocaleOut(BaseModel):
    code: str        # ISO-639-1, e.g. "hi"
    bcp47: str       # platform locale tag, e.g. "hi-IN"
    label: str       # native display name


class VoiceConfigOut(BaseModel):
    locales: list[VoiceLocaleOut]
    default_locale: str          # bcp47
    wake_word: str
    default_rate: float          # 0.0–1.0 (normalized speaking rate)
    default_pitch: float         # ~0.5–2.0


class VoiceSettingsOut(BaseModel):
    locale: str                  # bcp47 the client TTS should use
    rate: float
    pitch: float


class VoiceTurnRequest(BaseModel):
    transcript: str = Field(min_length=1, max_length=4000)
    conversation_id: str | None = None
    locale: str | None = None    # bcp47 or ISO-639-1


class VoiceTurnResponse(BaseModel):
    conversation_id: str
    transcript: str
    reply: MessageOut            # the assistant message (reuses chat contract)
    voice: VoiceSettingsOut      # how the client should synthesise the reply
