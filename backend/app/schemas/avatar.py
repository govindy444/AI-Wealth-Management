"""Pydantic schemas for the AI Avatar endpoints."""
from __future__ import annotations

from pydantic import BaseModel, Field

from app.models.avatar import AvatarExpression


class PersonaOut(BaseModel):
    id: str
    name: str
    title: str
    accent_color: str
    languages: list[str]
    default_language: str


class PresentRequest(BaseModel):
    # Text for the avatar to deliver. When omitted, the persona's localized
    # greeting is used.
    text: str | None = Field(default=None, max_length=4000)
    persona_id: str | None = None
    language: str | None = None


class AvatarSegmentOut(BaseModel):
    """A sentence-sized chunk the avatar animates/captions through."""

    text: str
    duration_ms: int


class AvatarPresentationOut(BaseModel):
    persona_id: str
    persona_name: str
    language: str
    expression: AvatarExpression
    text: str
    segments: list[AvatarSegmentOut]
    total_duration_ms: int
