"""Knowledge / RAG endpoints (`/api/v1/rag`).

Search the IDBI knowledge base and (when an LLM is configured) get a grounded,
cited answer. Works offline via the local embedder + in-memory store.
"""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Query
from pydantic import BaseModel

from app.ai.factory import get_llm
from app.ai.llm import LLMNotConfigured
from app.ai.orchestrator import Orchestrator
from app.core.dependencies import CurrentUser
from app.rag.retriever import get_retriever

router = APIRouter(prefix="/rag", tags=["rag"])


class RagPassageOut(BaseModel):
    title: str
    source: str
    text: str
    score: float


class RagSearchOut(BaseModel):
    query: str
    answer: str
    grounded: bool        # True when an LLM composed the answer from the passages
    passages: list[RagPassageOut]


class RagInfoOut(BaseModel):
    indexed_passages: int


@router.get("/info", response_model=RagInfoOut, summary="Knowledge base size")
async def info(user: CurrentUser) -> RagInfoOut:
    return RagInfoOut(indexed_passages=get_retriever().size)


@router.get(
    "/search",
    response_model=RagSearchOut,
    summary="Search the IDBI knowledge base (grounded answer + citations)",
)
async def search(
    user: CurrentUser,
    q: Annotated[str, Query(min_length=1, max_length=500)],
    k: Annotated[int, Query(ge=1, le=10)] = 3,
) -> RagSearchOut:
    retriever = get_retriever()
    passages = retriever.retrieve(q, top_k=k)
    out_passages = [
        RagPassageOut(title=p.title, source=p.source, text=p.text, score=p.score)
        for p in passages
    ]

    # Compose an answer: LLM-grounded when configured, else extractive (top passage).
    llm = get_llm()
    answer = ""
    grounded = False
    if passages and llm.enabled:
        try:
            answer = await Orchestrator(llm, retriever=retriever).respond(
                user=user, history=[], message=q
            )
            grounded = True
        except LLMNotConfigured:
            grounded = False
    if not answer:
        answer = passages[0].text if passages else "No relevant information found."

    return RagSearchOut(query=q, answer=answer, grounded=grounded, passages=out_passages)
