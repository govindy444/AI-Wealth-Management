"""Text embeddings.

`Embedder` is the seam. `HashingEmbedder` is a deterministic, dependency-free
bag-of-words hashing embedder — good enough for keyword-grounded retrieval over a
small product catalogue, and it runs anywhere with no model download or API key.
`OpenAIEmbedder` (httpx, lazy) is the production path for semantic embeddings.
"""
from __future__ import annotations

import hashlib
import math
import re
from abc import ABC, abstractmethod

_TOKEN = re.compile(r"[a-z0-9]+")

# Common words carry no retrieval signal — dropping them sharpens keyword matching.
_STOPWORDS = frozenset(
    "a an the is are was were be been being this that these those it its of for to "
    "with and or in on at by as i you we my your me us our do does did how can could "
    "should would what when where which who why if then than so up out about over "
    "into from have has had will shall may might not no yes get got need want".split()
)


def _tokenize(text: str) -> list[str]:
    tokens = []
    for raw in _TOKEN.findall(text.lower()):
        if raw in _STOPWORDS:
            continue
        # Naive singularization so "scams"/"scam", "loans"/"loan" match.
        if len(raw) > 3 and raw.endswith("s") and not raw.endswith("ss"):
            raw = raw[:-1]
        tokens.append(raw)
    return tokens


def _stable_hash(s: str) -> int:
    """Process-independent hash (builtin hash() is randomized per run)."""
    return int.from_bytes(hashlib.blake2b(s.encode(), digest_size=8).digest(), "big")


def _l2_normalize(vec: list[float]) -> list[float]:
    norm = math.sqrt(sum(v * v for v in vec))
    if norm == 0:
        return vec
    return [v / norm for v in vec]


class Embedder(ABC):
    dim: int

    @abstractmethod
    def embed(self, text: str) -> list[float]: ...

    def embed_many(self, texts: list[str]) -> list[list[float]]:
        return [self.embed(t) for t in texts]


class HashingEmbedder(Embedder):
    """Hashes tokens into a fixed-dimension, L2-normalized vector.

    Cosine similarity between two such vectors rises with shared vocabulary, so
    keyword-rich queries retrieve the right passages deterministically.
    """

    def __init__(self, dim: int = 512) -> None:
        self.dim = dim

    def embed(self, text: str) -> list[float]:
        vec = [0.0] * self.dim
        for token in _tokenize(text):
            # Deterministic hash → bucket; a second hash gives the sign.
            bucket = _stable_hash(token + "\x00idbi") % self.dim
            sign = 1.0 if (_stable_hash(token) & 1) == 0 else -1.0
            vec[bucket] += sign
        return _l2_normalize(vec)


class OpenAIEmbedder(Embedder):
    """OpenAI-compatible embeddings endpoint (also Ollama, Together, …)."""

    def __init__(self, *, api_key: str, model: str, base_url: str, dim: int = 1536) -> None:
        self.dim = dim
        self._api_key = api_key
        self._model = model
        self._base_url = base_url.rstrip("/")

    def embed(self, text: str) -> list[float]:
        return self.embed_many([text])[0]

    def embed_many(self, texts: list[str]) -> list[list[float]]:
        import httpx  # always available, but keep local for symmetry

        headers = {"Content-Type": "application/json"}
        if self._api_key:
            headers["Authorization"] = f"Bearer {self._api_key}"
        resp = httpx.post(
            f"{self._base_url}/embeddings",
            json={"model": self._model, "input": texts},
            headers=headers,
            timeout=30.0,
        )
        resp.raise_for_status()
        return [_l2_normalize(item["embedding"]) for item in resp.json()["data"]]
