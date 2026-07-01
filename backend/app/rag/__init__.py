"""Retrieval-Augmented Generation (Module 22).

Grounds the AI advisor in IDBI product/policy knowledge. Provider-agnostic and
zero-dependency by default: a deterministic local embedder + in-memory vector
store mean it runs offline, with OpenAI-compatible embeddings and Qdrant as
configurable seams for production.
"""
