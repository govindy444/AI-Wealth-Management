"""OpenAI-compatible provider via plain HTTP (httpx).

Talks the `/chat/completions` shape, which is implemented by OpenAI, Groq,
Together, OpenRouter, Mistral, local Ollama (`/v1`), LM Studio, vLLM, and more —
so a single provider covers "any LLM" the host wants by pointing `base_url` at it.
"""
from __future__ import annotations

import httpx

from app.ai.llm import LLMClient, LLMMessage, LLMNotConfigured

# Sensible default endpoints per known provider id.
_DEFAULT_BASE_URLS = {
    "openai": "https://api.openai.com/v1",
    "groq": "https://api.groq.com/openai/v1",
    "together": "https://api.together.xyz/v1",
    "openrouter": "https://openrouter.ai/api/v1",
    "mistral": "https://api.mistral.ai/v1",
    "ollama": "http://localhost:11434/v1",
}


class OpenAICompatibleLLM(LLMClient):
    def __init__(
        self,
        *,
        provider: str,
        api_key: str,
        model: str,
        base_url: str = "",
    ) -> None:
        self.provider = provider
        self.model = model
        self._api_key = api_key
        self._base_url = (base_url or _DEFAULT_BASE_URLS.get(provider, "")).rstrip("/")

    async def complete(
        self,
        *,
        system: str,
        messages: list[LLMMessage],
        max_tokens: int,
        temperature: float,
    ) -> str:
        if not self._base_url:
            raise LLMNotConfigured(f"No base URL configured for provider '{self.provider}'.")

        payload = {
            "model": self.model,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "messages": [
                {"role": "system", "content": system},
                *({"role": m.role, "content": m.content} for m in messages),
            ],
        }
        headers = {"Content-Type": "application/json"}
        if self._api_key:
            headers["Authorization"] = f"Bearer {self._api_key}"

        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(
                f"{self._base_url}/chat/completions", json=payload, headers=headers
            )
            resp.raise_for_status()
            data = resp.json()
        return data["choices"][0]["message"]["content"]
