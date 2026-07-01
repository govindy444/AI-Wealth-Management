"""Avatar presentation generation.

`AvatarPresenter` is the seam between the avatar service and the intelligence
that turns text into a deliverable performance: localized speech, an expression,
and timed sentence segments the client animates/captions through.

`RuleBasedAvatarPresenter` (today) detects a coarse expression from keywords,
splits text into sentences, and estimates timing — enough for a fully animated,
captioned avatar. Module 21 provides an `LlmAvatarPresenter` that performs real
multilingual translation and returns neural-TTS audio + viseme timings for
lip-sync, without changing this contract.
"""
from __future__ import annotations

import re
from abc import ABC, abstractmethod
from dataclasses import dataclass

from app.models.avatar import AvatarExpression, AvatarPersona

# Localized greetings. Full free-text translation arrives with the LLM in M21;
# these canned greetings make language selection tangible in the demo today.
_GREETINGS: dict[str, str] = {
    "en": "Hello, I'm {name}, your IDBI wealth advisor. How can I help you today?",
    "hi": "नमस्ते, मैं {name} हूँ, आपका IDBI वेल्थ सलाहकार। मैं आपकी कैसे मदद कर सकता हूँ?",
    "mr": "नमस्कार, मी {name}, तुमचा IDBI वेल्थ सल्लागार. मी तुम्हाला कशी मदत करू शकतो?",
    "ta": "வணக்கம், நான் {name}, உங்கள் IDBI செல்வ ஆலோசகர். நான் எவ்வாறு உதவ முடியும்?",
    "bn": "নমস্কার, আমি {name}, আপনার IDBI ওয়েলথ উপদেষ্টা। আমি কীভাবে সাহায্য করতে পারি?",
}

_POSITIVE = ("grew", "saved", "savings", "gain", "good", "great", "congrat",
             "on track", "surplus", "up ", "increase", "profit")
_CONCERN = ("debt", "loan", "risk", "overspend", "low balance", "fraud",
            "down", "loss", "decline", "high", "caution", "alert")
_THINK = ("?", "let's", "let us", "consider", "tell me", "plan", "estimate")

# ~150 words/min comfortable speaking pace → 400ms per word; minimum per segment.
_MS_PER_WORD = 400
_MIN_SEGMENT_MS = 900


@dataclass
class Segment:
    text: str
    duration_ms: int


@dataclass
class Presentation:
    text: str
    expression: AvatarExpression
    segments: list[Segment]

    @property
    def total_duration_ms(self) -> int:
        return sum(s.duration_ms for s in self.segments)


class AvatarPresenter(ABC):
    @abstractmethod
    def greeting(self, persona: AvatarPersona, language: str) -> str: ...

    @abstractmethod
    def present(
        self, text: str, persona: AvatarPersona, language: str
    ) -> Presentation: ...


class RuleBasedAvatarPresenter(AvatarPresenter):
    def greeting(self, persona: AvatarPersona, language: str) -> str:
        template = _GREETINGS.get(language, _GREETINGS["en"])
        return template.format(name=persona.name)

    def present(
        self, text: str, persona: AvatarPersona, language: str
    ) -> Presentation:
        clean = " ".join(text.strip().split())
        expression = self._expression(clean)
        segments = [
            Segment(text=s, duration_ms=self._duration(s))
            for s in self._split_sentences(clean)
        ]
        if not segments:
            segments = [Segment(text=clean, duration_ms=_MIN_SEGMENT_MS)]
        return Presentation(text=clean, expression=expression, segments=segments)

    @staticmethod
    def _expression(text: str) -> AvatarExpression:
        lower = text.lower()
        if any(w in lower for w in _CONCERN):
            return AvatarExpression.concerned
        if any(w in lower for w in _POSITIVE):
            return AvatarExpression.happy
        if any(w in lower for w in _THINK):
            return AvatarExpression.thinking
        return AvatarExpression.neutral

    @staticmethod
    def _split_sentences(text: str) -> list[str]:
        # Split on sentence terminators (Latin + Devanagari danda) keeping it simple.
        parts = re.split(r"(?<=[.!?。।])\s+", text)
        return [p.strip() for p in parts if p.strip()]

    @staticmethod
    def _duration(sentence: str) -> int:
        words = max(1, len(sentence.split()))
        return max(_MIN_SEGMENT_MS, words * _MS_PER_WORD)
