"""Tests for the AI orchestration layer (Module 21).

All run offline — no API key, no vendor SDK. They exercise provider selection,
the orchestrator, and the graceful fallback to the deterministic engine.
"""
import asyncio

from fastapi.testclient import TestClient

from app.ai.factory import build_llm
from app.ai.llm import LLMClient, LLMMessage
from app.ai.llm_chat_responder import LlmChatResponder
from app.ai.orchestrator import Orchestrator
from app.ai.providers.anthropic_provider import AnthropicLLM
from app.ai.providers.null_provider import NullLLM
from app.ai.providers.openai_provider import OpenAICompatibleLLM
from app.core.config import Settings
from app.main import app
from app.models.user import User
from app.services.chat_responder import RuleBasedChatResponder

client = TestClient(app)

_USER = User(id="u", email="demo@idbi.example", full_name="Demo User", hashed_password="x")


# ── provider selection ───────────────────────────────────────────
def test_no_key_disables_llm() -> None:
    llm = build_llm(Settings(llm_provider="anthropic", llm_api_key=""))
    assert isinstance(llm, NullLLM)
    assert llm.enabled is False


def test_anthropic_provider_selected_with_key() -> None:
    llm = build_llm(Settings(llm_provider="anthropic", llm_api_key="sk-test", llm_model="claude-opus-4-8"))
    assert isinstance(llm, AnthropicLLM)
    assert llm.provider == "anthropic"
    assert llm.model == "claude-opus-4-8"
    assert llm.enabled is True


def test_openai_compatible_provider_selected() -> None:
    llm = build_llm(Settings(llm_provider="openai", llm_api_key="sk-test", llm_model="gpt-4o-mini"))
    assert isinstance(llm, OpenAICompatibleLLM)
    assert llm.provider == "openai"


def test_ollama_needs_no_key() -> None:
    llm = build_llm(Settings(llm_provider="ollama", llm_api_key="", llm_model="llama3"))
    assert isinstance(llm, OpenAICompatibleLLM)
    assert llm.enabled is True  # keyless local provider


def test_provider_none_is_disabled() -> None:
    assert isinstance(build_llm(Settings(llm_provider="none")), NullLLM)


# ── orchestrator + fallback ──────────────────────────────────────
class _FakeLLM(LLMClient):
    provider = "fake"
    model = "fake-1"

    def __init__(self, reply: str = "", fail: bool = False) -> None:
        self._reply = reply
        self._fail = fail

    async def complete(self, *, system, messages, max_tokens, temperature) -> str:
        if self._fail:
            raise RuntimeError("boom")
        # Echo that the system prompt carried the persona + the user's question.
        assert "IDBI Wealth AI advisor" in system
        return self._reply


def test_llm_responder_uses_the_model() -> None:
    responder = LlmChatResponder(
        Orchestrator(_FakeLLM(reply="Invest via a monthly SIP in an index fund.")),
        RuleBasedChatResponder(),
    )
    reply = asyncio.run(responder.respond(_USER, [], "How should I invest?"))
    assert reply.content == "Invest via a monthly SIP in an index fund."


def test_llm_responder_falls_back_on_error() -> None:
    responder = LlmChatResponder(
        Orchestrator(_FakeLLM(fail=True)),
        RuleBasedChatResponder(),
    )
    reply = asyncio.run(responder.respond(_USER, [], "How should I invest?"))
    # Rule-based investment reply carries an explanation envelope.
    assert reply.explanation is not None
    assert "Demo" in reply.content


def test_llm_responder_falls_back_when_disabled() -> None:
    responder = LlmChatResponder(Orchestrator(NullLLM()), RuleBasedChatResponder())
    reply = asyncio.run(responder.respond(_USER, [], "hello"))
    assert "Demo" in reply.content  # greeting from the rule-based engine


def test_orchestrator_passes_history_and_context() -> None:
    captured = {}

    class _Capture(LLMClient):
        async def complete(self, *, system, messages, max_tokens, temperature) -> str:
            captured["system"] = system
            captured["messages"] = messages
            return "ok"

    orch = Orchestrator(_Capture())
    asyncio.run(orch.respond(
        user=_USER,
        history=[LLMMessage(role="user", content="hi"), LLMMessage(role="assistant", content="hello")],
        message="and now?",
        context="Net worth ₹6,33,790.",
    ))
    assert "Net worth" in captured["system"]
    assert captured["messages"][-1].content == "and now?"
    assert len(captured["messages"]) == 3


# ── status endpoint ──────────────────────────────────────────────
def test_ai_status_endpoint_reports_disabled_by_default() -> None:
    body = client.get("/api/v1/ai/status").json()
    # Default config has no key → disabled, deterministic fallback in use.
    assert body["enabled"] is False
    assert "provider" in body and "model" in body
