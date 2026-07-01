"""Avatar business logic: resolve persona + language and build a presentation.

Reply generation/translation is delegated to an [AvatarPresenter] (rule-based
today, LLM/neural-TTS from Module 21), keeping persona resolution separate from
the intelligence.
"""
from __future__ import annotations

from app.core.exceptions import NotFoundError
from app.repositories.avatar_repository import AvatarRepository
from app.schemas.avatar import (
    AvatarPresentationOut,
    AvatarSegmentOut,
    PersonaOut,
)
from app.services.avatar_presenter import AvatarPresenter


class AvatarService:
    def __init__(self, personas: AvatarRepository, presenter: AvatarPresenter) -> None:
        self._personas = personas
        self._presenter = presenter

    async def list_personas(self) -> list[PersonaOut]:
        personas = await self._personas.list_personas()
        return [
            PersonaOut(
                id=p.id,
                name=p.name,
                title=p.title,
                accent_color=p.accent_color,
                languages=p.languages,
                default_language=p.default_language,
            )
            for p in personas
        ]

    async def present(
        self,
        text: str | None,
        persona_id: str | None,
        language: str | None,
    ) -> AvatarPresentationOut:
        persona = await self._resolve_persona(persona_id)
        lang = language if (language and persona.supports(language)) else persona.default_language

        spoken = text.strip() if text and text.strip() else self._presenter.greeting(persona, lang)
        presentation = self._presenter.present(spoken, persona, lang)

        return AvatarPresentationOut(
            persona_id=persona.id,
            persona_name=persona.name,
            language=lang,
            expression=presentation.expression,
            text=presentation.text,
            segments=[
                AvatarSegmentOut(text=s.text, duration_ms=s.duration_ms)
                for s in presentation.segments
            ],
            total_duration_ms=presentation.total_duration_ms,
        )

    async def _resolve_persona(self, persona_id: str | None):
        if persona_id is not None:
            persona = await self._personas.get(persona_id)
            if persona is None:
                raise NotFoundError("Avatar persona not found.")
            return persona
        personas = await self._personas.list_personas()
        if not personas:
            raise NotFoundError("No avatar personas configured.")
        return personas[0]
