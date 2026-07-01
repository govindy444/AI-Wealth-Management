"""Operational monitoring endpoints (`/api/v1`).

Exposes Prometheus-scrapeable metrics, a JSON metrics snapshot for the demo
dashboard, and a readiness probe that verifies the database is reachable.
"""
from __future__ import annotations

from fastapi import APIRouter, Response, status
from pydantic import BaseModel
from sqlalchemy import text

from app import __version__
from app.core.logging import get_logger
from app.core.metrics import get_metrics_registry
from app.db.session import SessionLocal

router = APIRouter(tags=["system"])
_log = get_logger("monitoring")


class ReadinessResponse(BaseModel):
    status: str
    version: str
    checks: dict[str, str]


@router.get(
    "/metrics",
    summary="Prometheus metrics",
    response_class=Response,
    responses={200: {"content": {"text/plain": {}}}},
)
async def metrics() -> Response:
    text_body = get_metrics_registry().prometheus_text()
    return Response(content=text_body, media_type="text/plain; version=0.0.4")


@router.get("/metrics.json", summary="Metrics snapshot (JSON)")
async def metrics_json() -> dict:
    return get_metrics_registry().snapshot()


@router.get(
    "/ready",
    response_model=ReadinessResponse,
    summary="Readiness probe (checks dependencies)",
)
async def ready(response: Response) -> ReadinessResponse:
    checks: dict[str, str] = {}
    try:
        async with SessionLocal() as session:
            await session.execute(text("SELECT 1"))
        checks["database"] = "ok"
    except Exception as exc:  # pragma: no cover - exercised only on real outage
        _log.error("readiness_db_failed", error=str(exc))
        checks["database"] = "unavailable"

    ready_ok = all(v == "ok" for v in checks.values())
    if not ready_ok:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    return ReadinessResponse(
        status="ready" if ready_ok else "not_ready",
        version=__version__,
        checks=checks,
    )
