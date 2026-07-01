"""Vector store abstraction.

`InMemoryVectorStore` (default) does brute-force cosine search — fine for a small
product catalogue and needs nothing external. `QdrantVectorStore` (lazy) is the
production seam for scale.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass(frozen=True)
class Passage:
    text: str
    title: str
    source: str
    score: float = 0.0


@dataclass
class _Record:
    vector: list[float]
    text: str
    title: str
    source: str


def _cosine(a: list[float], b: list[float]) -> float:
    # Vectors are pre-normalized → cosine is just the dot product.
    return sum(x * y for x, y in zip(a, b, strict=False))


class VectorStore(ABC):
    @abstractmethod
    def add(self, *, vector: list[float], text: str, title: str, source: str) -> None: ...

    @abstractmethod
    def search(self, vector: list[float], top_k: int) -> list[Passage]: ...

    @abstractmethod
    def count(self) -> int: ...


class InMemoryVectorStore(VectorStore):
    def __init__(self) -> None:
        self._records: list[_Record] = []

    def add(self, *, vector: list[float], text: str, title: str, source: str) -> None:
        self._records.append(_Record(vector, text, title, source))

    def search(self, vector: list[float], top_k: int) -> list[Passage]:
        scored = [
            Passage(r.text, r.title, r.source, round(_cosine(vector, r.vector), 4))
            for r in self._records
        ]
        scored.sort(key=lambda p: p.score, reverse=True)
        return scored[:top_k]

    def count(self) -> int:
        return len(self._records)


class QdrantVectorStore(VectorStore):  # pragma: no cover - requires a running Qdrant
    """Production vector store backed by Qdrant (lazy `qdrant-client` import)."""

    def __init__(self, *, url: str, collection: str, dim: int) -> None:
        from qdrant_client import QdrantClient
        from qdrant_client.models import Distance, VectorParams

        self._collection = collection
        self._client = QdrantClient(url=url)
        if not self._client.collection_exists(collection):
            self._client.create_collection(
                collection,
                vectors_config=VectorParams(size=dim, distance=Distance.COSINE),
            )
        self._next_id = 0

    def add(self, *, vector: list[float], text: str, title: str, source: str) -> None:
        from qdrant_client.models import PointStruct

        self._client.upsert(
            self._collection,
            points=[PointStruct(
                id=self._next_id,
                vector=vector,
                payload={"text": text, "title": title, "source": source},
            )],
        )
        self._next_id += 1

    def search(self, vector: list[float], top_k: int) -> list[Passage]:
        hits = self._client.search(self._collection, query_vector=vector, limit=top_k)
        return [
            Passage(h.payload["text"], h.payload["title"], h.payload["source"], round(h.score, 4))
            for h in hits
        ]

    def count(self) -> int:
        return self._client.count(self._collection).count
