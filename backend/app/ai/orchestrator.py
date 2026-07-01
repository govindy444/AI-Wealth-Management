"""The AI orchestrator — the single place that turns a user turn into an LLM
prompt and back.

A deliberately lightweight, provider-neutral orchestrator (rather than a
framework like LangGraph, which couples to specific providers): it builds the
advisor system prompt, optionally grounds it with the user's financial context
(full RAG over IDBI docs arrives in Module 22), threads the conversation history,
and calls whichever `LLMClient` is configured.
"""
from __future__ import annotations

from app.ai.llm import LLMClient, LLMMessage
from app.models.user import User
from app.rag.retriever import Retriever

_SYSTEM_PROMPT = (
    "You are the IDBI Wealth AI advisor — a helpful, trustworthy personal "
    "wealth assistant for a digital banking customer in India.\n"
    "Guidelines:\n"
    "- Be concise, warm, and practical. Prefer plain language over jargon.\n"
    "- Amounts are in Indian Rupees (₹). Use Indian context (SIP, ELSS, FD, NPS, 80C).\n"
    "- Always explain the reasoning behind any suggestion (the 'why'), and note key risks.\n"
    "- Never promise guaranteed returns; market investments carry risk.\n"
    "- You are not a substitute for a licensed financial advisor for complex decisions.\n"
    "- If you don't have the data to answer precisely, say so and suggest where to look "
    "in the app (Dashboard, Spending, Goals, Portfolio)."
)


class Orchestrator:
    def __init__(self, llm: LLMClient, retriever: Retriever | None = None) -> None:
        self._llm = llm
        self._retriever = retriever

    @property
    def llm(self) -> LLMClient:
        return self._llm

    async def respond(
        self,
        *,
        user: User,
        history: list[LLMMessage],
        message: str,
        max_tokens: int = 1024,
        temperature: float = 0.4,
        context: str | None = None,
    ) -> str:
        first_name = user.full_name.split(" ")[0] if user.full_name else "there"
        system = _SYSTEM_PROMPT + f"\nThe customer's name is {first_name}."

        knowledge = self._retriever.as_context(message) if self._retriever else ""
        if knowledge:
            system += (
                "\n\nUse the following IDBI knowledge to answer accurately. "
                "Cite the product/topic name when you rely on it; if the knowledge "
                "doesn't cover the question, say so.\n\n" + knowledge
            )
        if context:
            system += f"\n\nRelevant context about the customer:\n{context}"

        messages = [*history, LLMMessage(role="user", content=message)]
        return await self._llm.complete(
            system=system,
            messages=messages,
            max_tokens=max_tokens,
            temperature=temperature,
        )
