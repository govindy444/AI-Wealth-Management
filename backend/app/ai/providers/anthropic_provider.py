"""Anthropic (Claude) provider via the official `anthropic` SDK.

The SDK is imported lazily so the rest of the app — and the test suite — runs
without it installed. Default model is `claude-opus-4-8`.
"""
from __future__ import annotations

from app.ai.llm import LLMClient, LLMMessage, LLMNotConfigured


class AnthropicLLM(LLMClient):
    provider = "anthropic"

    def __init__(self, *, api_key: str, model: str) -> None:
        self._api_key = api_key
        self.model = model or "claude-opus-4-8"
        self._client = None  # lazily constructed

    def _ensure_client(self):
        if self._client is None:
            try:
                from anthropic import AsyncAnthropic
            except ImportError as exc:  # pragma: no cover - depends on env
                raise LLMNotConfigured(
                    "The 'anthropic' package is not installed. "
                    "Run `pip install anthropic` to use the Anthropic provider."
                ) from exc
            self._client = AsyncAnthropic(api_key=self._api_key)
        return self._client

    async def complete(
        self,
        *,
        system: str,
        messages: list[LLMMessage],
        max_tokens: int,
        temperature: float,
    ) -> str:
        client = self._ensure_client()
        resp = await client.messages.create(
            model=self.model,
            max_tokens=max_tokens,
            system=system,
            messages=[{"role": m.role, "content": m.content} for m in messages],
        )
        return "".join(b.text for b in resp.content if getattr(b, "type", None) == "text")
