"""Avatar persona repository abstraction + in-memory implementation.

Personas are static configuration today; Module 20 can move them to the database
if the bank wants to manage them. Services depend on [AvatarRepository].
"""
from __future__ import annotations

from abc import ABC, abstractmethod

from app.models.avatar import AvatarPersona

_INDIC = ["en", "hi", "mr", "ta", "bn"]


class AvatarRepository(ABC):
    @abstractmethod
    async def list_personas(self) -> list[AvatarPersona]: ...

    @abstractmethod
    async def get(self, persona_id: str) -> AvatarPersona | None: ...


class InMemoryAvatarRepository(AvatarRepository):
    def __init__(self) -> None:
        self._personas: dict[str, AvatarPersona] = {}
        for p in self._seed():
            self._personas[p.id] = p

    @staticmethod
    def _seed() -> list[AvatarPersona]:
        return [
            AvatarPersona(
                id="aanya",
                name="Aanya",
                title="Wealth Advisor",
                accent_color="#6C4DF4",
                languages=_INDIC,
                default_language="en",
            ),
            AvatarPersona(
                id="vikram",
                name="Vikram",
                title="Investment Specialist",
                accent_color="#0E8F6E",
                languages=["en", "hi", "mr"],
                default_language="en",
            ),
        ]

    async def list_personas(self) -> list[AvatarPersona]:
        return list(self._personas.values())

    async def get(self, persona_id: str) -> AvatarPersona | None:
        return self._personas.get(persona_id)


_singleton = InMemoryAvatarRepository()


def get_avatar_repository() -> AvatarRepository:
    return _singleton
