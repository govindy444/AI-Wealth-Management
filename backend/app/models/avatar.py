"""AI Avatar domain model: the animated, multilingual banker personas.

Lightweight dataclasses for the in-memory phase. The avatar *presentation*
(expression, speech segments, localized text) is computed by the AvatarPresenter
service, not stored here.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum


class AvatarExpression(str, Enum):
    neutral = "neutral"
    happy = "happy"
    concerned = "concerned"
    thinking = "thinking"


@dataclass
class AvatarPersona:
    id: str
    name: str
    title: str
    # Hex accent colour the host UI can theme the avatar with.
    accent_color: str
    # ISO-639-1 language codes this persona can speak.
    languages: list[str] = field(default_factory=lambda: ["en"])
    default_language: str = "en"

    def supports(self, language: str) -> bool:
        return language in self.languages
