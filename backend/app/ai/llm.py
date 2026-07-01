from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Literal


class LLMNotConfigured(Exception):
    """Raised when no LLM provider is configured (no API key / provider=none).

    Callers catch this and fall back to the deterministic rule-based engines.
    """


@dataclass(frozen=True)
class LLMMessage:
    role: Literal["user", "assistant"]
    content: str


class LLMClient(ABC):
    """A chat-completion client. Implementations wrap a specific provider."""

    #: Human-readable provider id (e.g. "anthropic", "openai", "ollama", "none").
    provider: str = "none"
    #: The model id this client targets.
    model: str = ""

    @property
    def enabled(self) -> bool:
        """Whether this client can actually serve completions."""
        return True

    @abstractmethod
    async def complete(
        self,
        *,
        system: str,
        messages: list[LLMMessage],
        max_tokens: int,
        temperature: float,
    ) -> str:
        """Return the assistant's reply text for [messages] under [system]."""
