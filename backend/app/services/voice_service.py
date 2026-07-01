"""Voice Assistant business logic.

Voice is the chat advisor wrapped with speech framing: a recognised transcript
goes through the SAME `ChatService` (one brain), and the reply comes back with
the synthesis settings the client should use to speak it. Real server-side
ASR/neural-TTS plug in at Module 21 without changing this contract.
"""
from __future__ import annotations

from app.models.user import User
from app.schemas.voice import (
    VoiceConfigOut,
    VoiceLocaleOut,
    VoiceSettingsOut,
    VoiceTurnResponse,
)
from app.services.chat_service import ChatService

# Indic locale coverage advertised by the voice assistant.
_LOCALES = [
    VoiceLocaleOut(code="en", bcp47="en-IN", label="English"),
    VoiceLocaleOut(code="hi", bcp47="hi-IN", label="हिन्दी"),
    VoiceLocaleOut(code="mr", bcp47="mr-IN", label="मराठी"),
    VoiceLocaleOut(code="ta", bcp47="ta-IN", label="தமிழ்"),
    VoiceLocaleOut(code="bn", bcp47="bn-IN", label="বাংলা"),
]
_BY_BCP47 = {loc.bcp47: loc for loc in _LOCALES}
_BY_CODE = {loc.code: loc for loc in _LOCALES}
_DEFAULT = "en-IN"
_DEFAULT_RATE = 0.5
_DEFAULT_PITCH = 1.0


class VoiceService:
    def __init__(self, chat: ChatService) -> None:
        self._chat = chat

    def config(self) -> VoiceConfigOut:
        return VoiceConfigOut(
            locales=_LOCALES,
            default_locale=_DEFAULT,
            wake_word="Hey IDBI",
            default_rate=_DEFAULT_RATE,
            default_pitch=_DEFAULT_PITCH,
        )

    async def take_turn(
        self,
        user: User,
        transcript: str,
        conversation_id: str | None,
        locale: str | None,
    ) -> VoiceTurnResponse:
        reply = await self._chat.send_message(user, transcript, conversation_id)
        return VoiceTurnResponse(
            conversation_id=reply.conversation_id,
            transcript=transcript,
            reply=reply.message,
            voice=self._settings(locale),
        )

    @staticmethod
    def _settings(locale: str | None) -> VoiceSettingsOut:
        bcp47 = _DEFAULT
        if locale:
            if locale in _BY_BCP47:
                bcp47 = locale
            elif locale in _BY_CODE:
                bcp47 = _BY_CODE[locale].bcp47
        return VoiceSettingsOut(
            locale=bcp47, rate=_DEFAULT_RATE, pitch=_DEFAULT_PITCH
        )
