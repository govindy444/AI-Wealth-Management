"""Tests for the RAG layer (Module 22) — all offline (local embedder + memory store)."""
import asyncio

from fastapi.testclient import TestClient

from app.ai.llm import LLMClient, LLMMessage
from app.ai.orchestrator import Orchestrator
from app.main import app
from app.models.user import User
from app.rag.chunking import chunk_text
from app.rag.embeddings import HashingEmbedder
from app.rag.retriever import build_retriever

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}
_USER = User(id="u", email="demo@idbi.example", full_name="Demo User", hashed_password="x")


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


# ── embeddings ───────────────────────────────────────────────────
def test_hashing_embedder_is_deterministic_and_normalized() -> None:
    e = HashingEmbedder()
    v1 = e.embed("save tax under 80C with ELSS")
    v2 = e.embed("save tax under 80C with ELSS")
    assert v1 == v2
    norm = sum(x * x for x in v1) ** 0.5
    assert abs(norm - 1.0) < 1e-6


def test_similar_text_scores_higher_than_dissimilar() -> None:
    e = HashingEmbedder()
    q = e.embed("how do I save tax with 80C")
    near = e.embed("ELSS gives a tax deduction under section 80C")
    far = e.embed("gold etf inflation hedge diversifier")

    def cos(a, b):
        return sum(x * y for x, y in zip(a, b, strict=False))

    assert cos(q, near) > cos(q, far)


# ── chunking ─────────────────────────────────────────────────────
def test_chunking_splits_long_text_with_overlap() -> None:
    text = "Sentence number {}. ".format
    long = " ".join(text(i) for i in range(200))
    chunks = chunk_text(long, max_chars=300, overlap=60)
    assert len(chunks) > 1
    assert all(len(c) <= 320 for c in chunks)


# ── retriever ────────────────────────────────────────────────────
def test_retriever_finds_the_right_doc() -> None:
    r = build_retriever()
    assert r.size >= 11  # the seed corpus is ingested

    tax = r.retrieve("how can I save tax under section 80C")
    assert tax and "ELSS" in tax[0].title

    loan = r.retrieve("should I prepay my home loan EMI")
    assert loan and "Home Loan" in loan[0].title

    fraud = r.retrieve("is this OTP message asking to verify KYC a scam")
    assert fraud and "Fraud" in fraud[0].title


def test_retriever_returns_nothing_for_gibberish() -> None:
    r = build_retriever()
    assert r.retrieve("zzzqqqxyy", min_score=0.5) == []


# ── orchestrator grounding ───────────────────────────────────────
def test_orchestrator_injects_retrieved_knowledge_into_prompt() -> None:
    captured = {}

    class _Capture(LLMClient):
        async def complete(self, *, system, messages, max_tokens, temperature) -> str:
            captured["system"] = system
            return "ok"

    orch = Orchestrator(_Capture(), retriever=build_retriever())
    asyncio.run(orch.respond(
        user=_USER, history=[LLMMessage(role="user", content="x")][:0],
        message="how do I save tax under 80C?",
    ))
    # The ELSS knowledge passage was grounded into the system prompt.
    assert "ELSS" in captured["system"]
    assert "Section 80C" in captured["system"]


# ── endpoint ─────────────────────────────────────────────────────
def test_rag_search_requires_auth() -> None:
    assert client.get("/api/v1/rag/search?q=tax").status_code == 401


def test_rag_search_returns_cited_passages() -> None:
    body = client.get(
        "/api/v1/rag/search", params={"q": "how do I save tax 80C"},
        headers=_auth_headers(),
    ).json()
    assert body["passages"]
    assert "ELSS" in body["passages"][0]["title"]
    assert body["passages"][0]["source"]
    # No LLM key in tests → extractive (un-grounded) answer from the top passage.
    assert body["grounded"] is False
    assert body["answer"]


def test_rag_info_reports_index_size() -> None:
    body = client.get("/api/v1/rag/info", headers=_auth_headers()).json()
    assert body["indexed_passages"] >= 11
