"""Voice Assistant endpoints (`/api/v1/voice`)."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends

from app.ai.factory import get_chat_responder
from app.core.dependencies import CurrentUser
from app.repositories.chat_repository import ChatRepository, get_chat_repository
from app.schemas.voice import VoiceConfigOut, VoiceTurnRequest, VoiceTurnResponse
from app.services.chat_service import ChatService
from app.services.voice_service import VoiceService

router = APIRouter(prefix="/voice", tags=["voice"])


def get_voice_service(
    chats: Annotated[ChatRepository, Depends(get_chat_repository)],
) -> VoiceService:
    return VoiceService(ChatService(chats, get_chat_responder()))


VoiceDep = Annotated[VoiceService, Depends(get_voice_service)]


@router.get(
    "/config",
    response_model=VoiceConfigOut,
    summary="Supported voice locales, wake word, and default synthesis settings",
)
async def voice_config(user: CurrentUser, service: VoiceDep) -> VoiceConfigOut:
    return service.config()


@router.post(
    "/turn",
    response_model=VoiceTurnResponse,
    summary="Submit a recognised transcript and get a spoken-ready reply",
)
async def voice_turn(
    req: VoiceTurnRequest, user: CurrentUser, service: VoiceDep
) -> VoiceTurnResponse:
    return await service.take_turn(user, req.transcript, req.conversation_id, req.locale)
