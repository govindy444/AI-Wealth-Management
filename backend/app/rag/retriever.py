"""Retriever: embed a query and fetch the most relevant knowledge passages.

`build_retriever` selects the embedder + vector store from config (local
defaults), ingests the seed corpus (chunk → embed → index), and returns a
`Retriever`. `get_retriever` caches one process-wide instance.
"""
from __future__ import annotations

from functools import lru_cache

from app.core.config import Settings, get_settings
from app.core.logging import get_logger
from app.rag.chunking import chunk_text
from app.rag.embeddings import Embedder, HashingEmbedder, OpenAIEmbedder
from app.rag.knowledge import KNOWLEDGE_DOCS
from app.rag.vector_store import InMemoryVectorStore, Passage, VectorStore

_log = get_logger("rag")


class Retriever:
    def __init__(self, embedder: Embedder, store: VectorStore) -> None:
        self._embedder = embedder
        self._store = store

    def retrieve(self, query: str, *, top_k: int = 3, min_score: float = 0.05) -> list[Passage]:
        if not query.strip() or self._store.count() == 0:
            return []
        vector = self._embedder.embed(query)
        hits = self._store.search(vector, top_k)
        return [h for h in hits if h.score >= min_score]

    def as_context(self, query: str, *, top_k: int = 3) -> str:
        """Formats retrieved passages as a grounding block for the LLM prompt."""
        passages = self.retrieve(query, top_k=top_k)
        if not passages:
            return ""
        return "\n\n".join(f"[{p.title} — {p.source}]\n{p.text}" for p in passages)

    @property
    def size(self) -> int:
        return self._store.count()


def _build_embedder(settings: Settings) -> Embedder:
    provider = (settings.embedding_provider or "hashing").lower()
    if provider == "hashing":
        return HashingEmbedder()
    # OpenAI-compatible embeddings (also Ollama/Together via base_url).
    base_url = settings.embedding_base_url or "https://api.openai.com/v1"
    return OpenAIEmbedder(
        api_key=settings.embedding_api_key,
        model=settings.embedding_model or "text-embedding-3-small",
        base_url=base_url,
    )


def _build_store(settings: Settings, dim: int) -> VectorStore:
    if (settings.vector_store or "memory").lower() == "qdrant":  # pragma: no cover
        from app.rag.vector_store import QdrantVectorStore

        return QdrantVectorStore(
            url=settings.qdrant_url,
            collection=settings.qdrant_collection,
            dim=dim,
        )
    return InMemoryVectorStore()


def build_retriever(settings: Settings | None = None) -> Retriever:
    settings = settings or get_settings()
    embedder = _build_embedder(settings)
    store = _build_store(settings, embedder.dim)

    # Ingest the seed corpus: chunk → embed (title + chunk so the title's
    # keywords count toward retrieval) → index.
    for doc in KNOWLEDGE_DOCS:
        for chunk in chunk_text(doc.text):
            store.add(
                vector=embedder.embed(f"{doc.title}. {chunk}"),
                text=chunk,
                title=doc.title,
                source=doc.source,
            )
    _log.info("rag_ingested", passages=store.count())
    return Retriever(embedder, store)


@lru_cache(maxsize=1)
def get_retriever() -> Retriever:
    return build_retriever(get_settings())
