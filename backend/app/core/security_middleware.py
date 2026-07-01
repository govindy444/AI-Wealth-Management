"""Security middleware: hardened response headers + a simple rate limiter.

Headers are always on (they don't affect behavior). The rate limiter is opt-in
via config (off in sandbox/tests) and backed by an in-memory window — production
swaps in Redis (Module 24).
"""
from __future__ import annotations

import time
from collections import defaultdict

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

# Paths whose HTML must load external assets (Swagger/ReDoc) — skip strict CSP.
_CSP_EXEMPT = ("/docs", "/redoc", "/openapi.json")


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, *, hsts: bool = False) -> None:
        super().__init__(app)
        self._hsts = hsts

    async def dispatch(self, request: Request, call_next) -> Response:
        response = await call_next(request)
        h = response.headers
        h.setdefault("X-Content-Type-Options", "nosniff")
        h.setdefault("X-Frame-Options", "DENY")
        h.setdefault("Referrer-Policy", "no-referrer")
        h.setdefault("X-XSS-Protection", "0")  # OWASP: disable legacy auditor
        h.setdefault("Permissions-Policy", "geolocation=(), microphone=(), camera=()")
        h.setdefault("Cache-Control", "no-store")
        if not request.url.path.startswith(_CSP_EXEMPT):
            h.setdefault(
                "Content-Security-Policy",
                "default-src 'none'; frame-ancestors 'none'; base-uri 'none'",
            )
        if self._hsts:
            h.setdefault(
                "Strict-Transport-Security", "max-age=31536000; includeSubDomains"
            )
        return response


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Fixed-window per-client rate limit. Returns 429 when exceeded."""

    def __init__(self, app, *, limit: int = 120, window_seconds: int = 60) -> None:
        super().__init__(app)
        self._limit = limit
        self._window = window_seconds
        self._hits: dict[str, tuple[float, int]] = defaultdict(lambda: (0.0, 0))

    async def dispatch(self, request: Request, call_next) -> Response:
        client = request.client.host if request.client else "unknown"
        now = time.monotonic()
        start, count = self._hits[client]
        if now - start >= self._window:
            start, count = now, 0
        count += 1
        self._hits[client] = (start, count)

        if count > self._limit:
            retry_after = max(1, int(self._window - (now - start)))
            return JSONResponse(
                status_code=429,
                content={
                    "error": {
                        "code": "rate_limited",
                        "message": "Too many requests. Please slow down.",
                        "details": {},
                    }
                },
                headers={"Retry-After": str(retry_after)},
            )
        return await call_next(request)
