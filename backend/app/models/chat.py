"""Chat domain models: conversations and messages.

Lightweight dataclasses for the in-memory phase; the SQLAlchemy mapping and
Redis-backed conversational memory land in Modules 20–21. The `Message.explanation`
field carries the Explainable-AI envelope when the assistant makes a claim or
recommendation worth justifying.
"""
from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from datetime import UTC, datetime
from enum import Enum
from typing import Any


def _now() -> datetime:
    return datetime.now(UTC)


def _new_id(prefix: str) -> str:
    return f"{prefix}_{uuid.uuid4().hex[:12]}"


class MessageRole(str, Enum):
    user = "user"
    assistant = "assistant"


@dataclass
class Message:
    role: MessageRole
    content: str
    id: str = field(default_factory=lambda: _new_id("msg"))
    created_at: datetime = field(default_factory=_now)
    # Optional Explainable-AI envelope (dict matching ExplanationOut) for
    # assistant messages that make a recommendation/claim.
    explanation: dict[str, Any] | None = None


@dataclass
class Conversation:
    user_id: str
    id: str = field(default_factory=lambda: _new_id("conv"))
    title: str = "New conversation"
    created_at: datetime = field(default_factory=_now)
    updated_at: datetime = field(default_factory=_now)
    messages: list[Message] = field(default_factory=list)

    def add(self, message: Message) -> Message:
        self.messages.append(message)
        self.updated_at = message.created_at
        return message
