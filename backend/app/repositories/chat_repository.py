"""Chat repository abstraction + in-memory implementation.

Conversations are stored per user. Module 20 replaces this with a Postgres-backed
repository (messages table) plus Redis for hot conversational memory; services
depend only on [ChatRepository].
"""
from __future__ import annotations

from abc import ABC, abstractmethod

from app.models.chat import Conversation


class ChatRepository(ABC):
    @abstractmethod
    async def create(self, conversation: Conversation) -> Conversation: ...

    @abstractmethod
    async def get(self, user_id: str, conversation_id: str) -> Conversation | None: ...

    @abstractmethod
    async def list_for_user(self, user_id: str) -> list[Conversation]: ...

    @abstractmethod
    async def save(self, conversation: Conversation) -> Conversation: ...

    @abstractmethod
    async def delete(self, user_id: str, conversation_id: str) -> bool: ...


class InMemoryChatRepository(ChatRepository):
    def __init__(self) -> None:
        self._by_user: dict[str, dict[str, Conversation]] = {}

    async def create(self, conversation: Conversation) -> Conversation:
        self._by_user.setdefault(conversation.user_id, {})[conversation.id] = conversation
        return conversation

    async def get(self, user_id: str, conversation_id: str) -> Conversation | None:
        return self._by_user.get(user_id, {}).get(conversation_id)

    async def list_for_user(self, user_id: str) -> list[Conversation]:
        convos = list(self._by_user.get(user_id, {}).values())
        # Most-recently-updated first.
        return sorted(convos, key=lambda c: c.updated_at, reverse=True)

    async def save(self, conversation: Conversation) -> Conversation:
        self._by_user.setdefault(conversation.user_id, {})[conversation.id] = conversation
        return conversation

    async def delete(self, user_id: str, conversation_id: str) -> bool:
        return self._by_user.get(user_id, {}).pop(conversation_id, None) is not None


# Process-wide singleton for the in-memory phase.
_singleton = InMemoryChatRepository()


def get_chat_repository() -> ChatRepository:
    return _singleton
