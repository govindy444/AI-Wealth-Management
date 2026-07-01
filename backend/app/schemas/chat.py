"""Pydantic request/response schemas for the AI chat endpoints."""
from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field

from app.models.chat import MessageRole
from app.schemas.banking import ExplanationOut


class SendMessageRequest(BaseModel):
    # When omitted, a new conversation is started.
    conversation_id: str | None = None
    message: str = Field(min_length=1, max_length=4000)


class MessageOut(BaseModel):
    id: str
    role: MessageRole
    content: str
    created_at: datetime
    explanation: ExplanationOut | None = None


class SendMessageResponse(BaseModel):
    conversation_id: str
    title: str
    message: MessageOut  # the assistant reply


class ConversationOut(BaseModel):
    id: str
    title: str
    created_at: datetime
    updated_at: datetime
    messages: list[MessageOut]


class ConversationSummaryOut(BaseModel):
    id: str
    title: str
    updated_at: datetime
    message_count: int
    last_message: str | None = None


class MessageResponse(BaseModel):
    message: str
