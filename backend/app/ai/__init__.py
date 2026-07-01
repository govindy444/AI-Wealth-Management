"""AI orchestration layer (Module 21).

Provider-agnostic LLM access: the rest of the app depends only on the `LLMClient`
contract, and a factory selects the concrete provider (Anthropic, any
OpenAI-compatible endpoint, or a no-op that triggers deterministic fallback)
from configuration. This keeps the platform usable with *any* LLM the bank
prefers — or none at all.
"""
