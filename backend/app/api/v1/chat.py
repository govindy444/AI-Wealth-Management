"""AI chat endpoints (`/api/v1/chat`)."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status

from app.ai.factory import get_chat_responder
from app.core.dependencies import CurrentUser
from app.repositories.chat_repository import ChatRepository, get_chat_repository
from app.schemas.chat import (
    ConversationOut,
    ConversationSummaryOut,
    MessageResponse,
    SendMessageRequest,
    SendMessageResponse,
)
from app.services.chat_service import ChatService

router = APIRouter(prefix="/chat", tags=["chat"])


def get_chat_service(
    chats: Annotated[ChatRepository, Depends(get_chat_repository)],
) -> ChatService:
    return ChatService(chats, get_chat_responder())


ChatDep = Annotated[ChatService, Depends(get_chat_service)]


@router.post(
    "/messages",
    response_model=SendMessageResponse,
    summary="Send a message and get the assistant's reply",
)
async def send_message(
    req: SendMessageRequest, user: CurrentUser, service: ChatDep
) -> SendMessageResponse:
    return await service.send_message(user, req.message, req.conversation_id)


@router.get(
    "/conversations",
    response_model=list[ConversationSummaryOut],
    summary="List the current user's conversations",
)
async def list_conversations(
    user: CurrentUser, service: ChatDep
) -> list[ConversationSummaryOut]:
    return await service.list_conversations(user)


@router.get(
    "/conversations/{conversation_id}",
    response_model=ConversationOut,
    summary="Fetch a full conversation with all messages",
)
async def get_conversation(
    conversation_id: str, user: CurrentUser, service: ChatDep
) -> ConversationOut:
    return await service.get_conversation(user, conversation_id)


@router.delete(
    "/conversations/{conversation_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Delete a conversation",
)
async def delete_conversation(
    conversation_id: str, user: CurrentUser, service: ChatDep
) -> MessageResponse:
    await service.delete_conversation(user, conversation_id)
    return MessageResponse(message="Conversation deleted.")
