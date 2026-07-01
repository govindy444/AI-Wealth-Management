"""Request observability middleware: correlation IDs, access logs, metrics.

Each request gets a correlation ID (honouring an inbound `X-Request-ID` so a
trace can span the SDK → backend), bound into the structlog context so every log
line for that request is correlated. On completion it logs a structured access
entry, records latency/status into the metrics registry, and returns the request
ID + server timing to the caller.
"""
from __future__ import annotations

import time
import uuid

import structlog
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from app.core.logging import get_logger
from app.core.metrics import get_metrics_registry

_REQUEST_ID_HEADER = "X-Request-ID"


class RequestObservabilityMiddleware(BaseHTTPMiddleware):
    def __init__(self, app) -> None:
        super().__init__(app)
        self._log = get_logger("access")
        self._metrics = get_metrics_registry()

    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = request.headers.get(_REQUEST_ID_HEADER) or uuid.uuid4().hex
        structlog.contextvars.bind_contextvars(request_id=request_id)
        request.state.request_id = request_id

        start = time.perf_counter()
        status_code = 500
        try:
            response = await call_next(request)
            status_code = response.status_code
            return self._finish(request, response, request_id, start, status_code)
        except Exception:
            duration_ms = (time.perf_counter() - start) * 1000
            self._record(request, 500, duration_ms, request_id, failed=True)
            raise
        finally:
            structlog.contextvars.unbind_contextvars("request_id")

    def _finish(
        self,
        request: Request,
        response: Response,
        request_id: str,
        start: float,
        status_code: int,
    ) -> Response:
        duration_ms = (time.perf_counter() - start) * 1000
        response.headers[_REQUEST_ID_HEADER] = request_id
        response.headers["X-Response-Time-ms"] = f"{duration_ms:.1f}"
        self._record(request, status_code, duration_ms, request_id)
        return response

    def _record(
        self,
        request: Request,
        status_code: int,
        duration_ms: float,
        request_id: str,
        *,
        failed: bool = False,
    ) -> None:
        # Use the matched route template (e.g. /notifications/{id}) to keep metric
        # cardinality bounded — never the raw path with ids baked in.
        route = _route_template(request)
        self._metrics.record_request(
            request.method, route, status_code, duration_ms
        )
        log = self._log.bind(
            method=request.method,
            path=request.url.path,
            route=route,
            status=status_code,
            duration_ms=round(duration_ms, 1),
            request_id=request_id,
        )
        if failed or status_code >= 500:
            log.error("request_failed")
        else:
            log.info("request_completed")


def _route_template(request: Request) -> str:
    route = request.scope.get("route")
    path = getattr(route, "path", None)
    if path:
        return str(path)
    return request.url.path or "unknown"
