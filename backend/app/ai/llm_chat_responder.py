from __future__ import annotations

from app.ai.llm import LLMMessage, LLMNotConfigured
from app.ai.orchestrator import Orchestrator
from app.core.logging import get_logger
from app.models.chat import Message, MessageRole
from app.models.user import User
from app.services.chat_responder import ChatResponder, Reply

_log = get_logger("ai.chat")


class LlmChatResponder(ChatResponder):
    def __init__(
        self,
        orchestrator: Orchestrator,
        fallback: ChatResponder,
        *,
        max_tokens: int = 1024,
        temperature: float = 0.4,
    ) -> None:
        self._orchestrator = orchestrator
        self._fallback = fallback
        self._max_tokens = max_tokens
        self._temperature = temperature

    async def respond(
        self, user: User, history: list[Message], message: str
    ) -> Reply:
        if not self._orchestrator.llm.enabled:
            return await self._fallback.respond(user, history, message)

        try:
            llm_history = [
                LLMMessage(
                    role="assistant" if m.role == MessageRole.assistant else "user",
                    content=m.content,
                )
                for m in history
            ]
            text = await self._orchestrator.respond(
                user=user,
                history=llm_history,
                message=message,
                max_tokens=self._max_tokens,
                temperature=self._temperature,
            )
            if not text or not text.strip():
                return await self._fallback.respond(user, history, message)
            return Reply(content=text.strip())
        except LLMNotConfigured:
            return await self._fallback.respond(user, history, message)
        except Exception as exc:  # noqa: BLE001 - never let the LLM break chat
            _log.warning("llm_chat_failed", error=str(exc))
            return await self._fallback.respond(user, history, message)
