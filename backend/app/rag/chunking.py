"""Document chunking for ingestion."""
from __future__ import annotations


def chunk_text(text: str, *, max_chars: int = 700, overlap: int = 120) -> list[str]:
    """Split [text] into overlapping chunks on paragraph/sentence boundaries.

    Keeps chunks under [max_chars] with [overlap] characters of context carried
    between adjacent chunks so a passage isn't split mid-thought.
    """
    text = " ".join(text.split())
    if len(text) <= max_chars:
        return [text] if text else []

    chunks: list[str] = []
    start = 0
    while start < len(text):
        end = min(start + max_chars, len(text))
        # Prefer to break at a sentence/space boundary near the limit.
        if end < len(text):
            window = text.rfind(". ", start, end)
            if window == -1:
                window = text.rfind(" ", start, end)
            if window > start:
                end = window + 1
        chunks.append(text[start:end].strip())
        if end >= len(text):
            break
        start = max(end - overlap, start + 1)
    return [c for c in chunks if c]
