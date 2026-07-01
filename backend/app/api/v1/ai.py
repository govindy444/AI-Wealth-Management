"""AI status endpoint (`/api/v1/ai`).

Advertises which LLM provider/model is active so the app (and ops) can show
"Powered by …" and confirm whether AI features are live or running on the
deterministic fallback.
"""
from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel

from app.ai.factory import get_llm

router = APIRouter(prefix="/ai", tags=["ai"])


class AIStatusOut(BaseModel):
    enabled: bool          # True when a real LLM is configured
    provider: str          # anthropic | openai | ollama | none | ...
    model: str


@router.get("/status", response_model=AIStatusOut, summary="Active LLM provider/model")
async def status() -> AIStatusOut:
    llm = get_llm()
    return AIStatusOut(enabled=llm.enabled, provider=llm.provider, model=llm.model)
