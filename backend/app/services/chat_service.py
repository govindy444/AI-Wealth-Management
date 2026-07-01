"""Chat business logic: manage conversations and generate assistant replies.

The actual reply generation is delegated to a [ChatResponder] (rule-based today,
LLM/LangGraph from Module 21), keeping persistence and orchestration concerns
separate from the intelligence.
"""
from __future__ import annotations

from app.core.exceptions import NotFoundError
from app.models.chat import Conversation, Message, MessageRole
from app.models.user import User
from app.repositories.chat_repository import ChatRepository
from app.schemas.chat import (
    ConversationOut,
    ConversationSummaryOut,
    MessageOut,
    SendMessageResponse,
)
from app.services.chat_responder import ChatResponder, title_from_first_message


class ChatService:
    def __init__(self, chats: ChatRepository, responder: ChatResponder) -> None:
        self._chats = chats
        self._responder = responder

    async def send_message(
        self, user: User, message: str, conversation_id: str | None
    ) -> SendMessageResponse:
        conversation = await self._resolve_conversation(user, conversation_id, message)

        # Persist the user's message, then generate + persist the reply.
        history = list(conversation.messages)
        conversation.add(Message(role=MessageRole.user, content=message))

        reply = await self._responder.respond(user, history, message)
        assistant = conversation.add(
            Message(
                role=MessageRole.assistant,
                content=reply.content,
                explanation=reply.explanation,
            )
        )
        await self._chats.save(conversation)

        return SendMessageResponse(
            conversation_id=conversation.id,
            title=conversation.title,
            message=self._to_message_out(assistant),
        )

    async def get_conversation(self, user: User, conversation_id: str) -> ConversationOut:
        conversation = await self._chats.get(user.id, conversation_id)
        if conversation is None:
            raise NotFoundError("Conversation not found.")
        return ConversationOut(
            id=conversation.id,
            title=conversation.title,
            created_at=conversation.created_at,
            updated_at=conversation.updated_at,
            messages=[self._to_message_out(m) for m in conversation.messages],
        )

    async def list_conversations(self, user: User) -> list[ConversationSummaryOut]:
        conversations = await self._chats.list_for_user(user.id)
        return [
            ConversationSummaryOut(
                id=c.id,
                title=c.title,
                updated_at=c.updated_at,
                message_count=len(c.messages),
                last_message=c.messages[-1].content if c.messages else None,
            )
            for c in conversations
        ]

    async def delete_conversation(self, user: User, conversation_id: str) -> None:
        deleted = await self._chats.delete(user.id, conversation_id)
        if not deleted:
            raise NotFoundError("Conversation not found.")

    # ── helpers ──────────────────────────────────────────────────
    async def _resolve_conversation(
        self, user: User, conversation_id: str | None, first_message: str
    ) -> Conversation:
        if conversation_id is not None:
            existing = await self._chats.get(user.id, conversation_id)
            if existing is None:
                raise NotFoundError("Conversation not found.")
            return existing
        conversation = Conversation(
            user_id=user.id, title=title_from_first_message(first_message)
        )
        return await self._chats.create(conversation)

    @staticmethod
    def _to_message_out(m: Message) -> MessageOut:
        return MessageOut(
            id=m.id,
            role=m.role,
            content=m.content,
            created_at=m.created_at,
            explanation=m.explanation,
        )
