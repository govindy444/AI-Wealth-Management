"""Assistant reply generation.

`ChatResponder` is the seam between the chat service and the intelligence that
produces replies. Module 21 (AI orchestration) provides a `LangGraphChatResponder`
that runs a stateful LangGraph with RAG + tools against a real LLM. Until then,
`RuleBasedChatResponder` gives genuinely useful, intent-aware answers so the chat
experience is functional end-to-end and the contract (text + optional Explainable
-AI envelope) is exercised.
"""
from __future__ import annotations

import re
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any

from app.models.chat import Message
from app.models.user import User


@dataclass
class Reply:
    content: str
    explanation: dict[str, Any] | None = None


class ChatResponder(ABC):
    @abstractmethod
    async def respond(
        self, user: User, history: list[Message], message: str
    ) -> Reply: ...


class RuleBasedChatResponder(ChatResponder):
    """Deterministic intent router. Replaced by the LLM responder in Module 21."""

    async def respond(
        self, user: User, history: list[Message], message: str
    ) -> Reply:
        first_name = user.full_name.split(" ")[0] if user.full_name else "there"
        text = message.lower().strip()

        for matcher, builder in self._intents():
            if matcher(text):
                return builder(self, first_name)
        return self._fallback(first_name)

    # ── intent table (ordered; first match wins) ─────────────────
    def _intents(self):
        def has(*words: str):
            return lambda t: any(re.search(rf"\b{w}\b", t) for w in words)

        return [
            (has("hi", "hello", "hey", "namaste"), RuleBasedChatResponder._greeting),
            (has("invest", "investment", "mutual", "sip", "fund", "equity"),
             RuleBasedChatResponder._invest),
            (has("debt", "loan", "emi", "credit"), RuleBasedChatResponder._debt),
            (has("save", "saving", "savings"), RuleBasedChatResponder._save),
            (has("goal", "goals", "retire", "retirement"), RuleBasedChatResponder._goal),
            (has("spend", "spending", "budget", "expense", "expenses"),
             RuleBasedChatResponder._spending),
            (has("net", "worth", "balance", "wealth"), RuleBasedChatResponder._networth),
            (has("help", "what", "can", "do", "who"), RuleBasedChatResponder._help),
        ]

    # ── builders ─────────────────────────────────────────────────
    def _greeting(self, name: str) -> Reply:
        return Reply(
            f"Hello {name}! I'm your IDBI Wealth AI advisor. I can help you "
            "understand your net worth, plan goals, review spending, and explore "
            "investments — all with clear reasoning. What would you like to look at?"
        )

    def _invest(self, name: str) -> Reply:
        return Reply(
            f"{name}, based on a balanced profile I'd suggest spreading new "
            "investments across an equity index fund (growth), a short-duration "
            "debt fund (stability), and continuing any SIPs you already hold. "
            "Start small and automate monthly contributions.",
            explanation={
                "summary": "A diversified, SIP-first approach suits most salaried investors.",
                "reasons": [
                    "Diversification across equity and debt reduces single-asset risk.",
                    "Rupee-cost averaging via SIPs smooths out market timing.",
                ],
                "risks": [
                    "Equity funds can fall in the short term; invest only surplus "
                    "you won't need for 3–5 years.",
                ],
                "benefits": ["Long-term compounding with a manageable risk level."],
                "alternatives": [
                    "A target-date / hybrid fund if you prefer a single hands-off product.",
                ],
                "citations": ["General asset-allocation guidance (not personalised advice)."],
                "confidence": 0.72,
            },
        )

    def _debt(self, name: str) -> Reply:
        return Reply(
            f"{name}, the fastest win is usually to clear high-interest debt first "
            "— typically your credit card — before prepaying lower-interest loans "
            "like a home loan. Want me to estimate the interest you'd save?",
            explanation={
                "summary": "Prioritise the highest-interest balance to reduce total interest paid.",
                "reasons": [
                    "Credit cards carry far higher APR than secured loans.",
                    "Every rupee toward the costliest debt has the highest guaranteed return.",
                ],
                "risks": ["Keep an emergency buffer; don't divert all cash to repayment."],
                "benefits": ["Lower interest outgo and improved monthly cash flow."],
                "alternatives": ["The 'snowball' method (smallest balance first) for motivation."],
                "citations": ["Standard debt-avalanche guidance."],
                "confidence": 0.8,
            },
        )

    def _save(self, name: str) -> Reply:
        return Reply(
            f"A simple rule that works well, {name}: aim to save at least 20% of "
            "your take-home pay. Automate a transfer to a separate savings or "
            "liquid fund on payday so it happens before you spend."
        )

    def _goal(self, name: str) -> Reply:
        return Reply(
            f"Let's make it concrete, {name}. Tell me the goal, the target amount, "
            "and the timeline (e.g. ₹10L for a car in 4 years) and I'll work out the "
            "monthly SIP needed and a suggested fund mix. The Goal Planner can track "
            "progress for you."
        )

    def _spending(self, name: str) -> Reply:
        return Reply(
            f"{name}, I can break your spending into categories and flag where it's "
            "drifting up month over month. The Spending Analytics tab shows trends "
            "and lets you set category budgets with alerts."
        )

    def _networth(self, name: str) -> Reply:
        return Reply(
            f"Your net worth is your assets (savings, deposits, investments) minus "
            f"your liabilities (cards, loans), {name}. The Dashboard shows the live "
            "figure with this month's change — open it for the full breakdown."
        )

    def _help(self, name: str) -> Reply:
        return Reply(
            f"Happy to help, {name}. I can: explain your net worth and accounts, "
            "review spending, plan goals with SIP maths, suggest investments, and "
            "help prioritise debt — always with the reasoning behind it. Just ask "
            "in plain language."
        )

    def _fallback(self, name: str) -> Reply:
        return Reply(
            f"I want to make sure I help with the right thing, {name}. I can talk "
            "through your net worth, spending, savings, goals, investments, or debt "
            "— which of those is on your mind?"
        )


def title_from_first_message(message: str) -> str:
    """Derives a short conversation title from the opening user message."""
    clean = " ".join(message.strip().split())
    if not clean:
        return "New conversation"
    return clean[:48] + ("…" if len(clean) > 48 else "")
