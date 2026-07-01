
from __future__ import annotations

from app.ai.llm import LLMClient
from app.ai.providers.anthropic_provider import AnthropicLLM
from app.ai.providers.null_provider import NullLLM
from app.ai.providers.openai_provider import OpenAICompatibleLLM
from app.core.config import Settings, get_settings

_KEYLESS = {"ollama", "local"}
_OPENAI_COMPATIBLE = {
    "openai", "groq", "together", "openrouter", "mistral", "ollama",
    "local", "openai_compatible",
}


def build_llm(settings: Settings) -> LLMClient:
    provider = (settings.llm_provider or "none").strip().lower()
    if provider in ("none", ""):
        return NullLLM()

    needs_key = provider not in _KEYLESS
    if needs_key and not settings.llm_api_key:
        return NullLLM()

    if provider == "anthropic":
        return AnthropicLLM(api_key=settings.llm_api_key, model=settings.llm_model)

    if provider in _OPENAI_COMPATIBLE:
        return OpenAICompatibleLLM(
            provider=provider,
            api_key=settings.llm_api_key,
            model=settings.llm_model,
            base_url=settings.llm_base_url,
        )

    return NullLLM()


def get_llm() -> LLMClient:
    return build_llm(get_settings())


def build_chat_responder(settings: Settings | None = None):
    """Builds the chat responder used by the chat *and* voice modules.

    Returns an LLM-backed responder (with rule-based fallback) when an LLM is
    configured; otherwise the responder still works and simply uses the
    deterministic engine.
    """
    from app.ai.llm_chat_responder import LlmChatResponder
    from app.ai.orchestrator import Orchestrator
    from app.rag.retriever import get_retriever
    from app.services.chat_responder import RuleBasedChatResponder

    settings = settings or get_settings()
    return LlmChatResponder(
        Orchestrator(build_llm(settings), retriever=get_retriever()),
        RuleBasedChatResponder(),
        max_tokens=settings.llm_max_tokens,
        temperature=settings.llm_temperature,
    )


def get_chat_responder():
    return build_chat_responder(get_settings())
