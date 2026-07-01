"""No-op provider used when no LLM is configured."""
from __future__ import annotations

from app.ai.llm import LLMClient, LLMMessage, LLMNotConfigured


class NullLLM(LLMClient):
    provider = "none"
    model = ""

    @property
    def enabled(self) -> bool:
        return False

    async def complete(
        self,
        *,
        system: str,
        messages: list[LLMMessage],
        max_tokens: int,
        temperature: float,
    ) -> str:
        raise LLMNotConfigured(
            "No LLM provider configured. Set LLM_PROVIDER and LLM_API_KEY "
            "(or use a local provider like Ollama)."
        )
