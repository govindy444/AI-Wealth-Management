"""FastAPI application factory for the IDBI Wealth AI backend.

Run locally:
    uvicorn app.main:app --reload
Docs:
    http://localhost:8000/docs   (Swagger)
    http://localhost:8000/redoc  (ReDoc)
"""
from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import __version__
from app.api.v1 import api_router
from app.core.config import get_settings
from app.core.exceptions import register_exception_handlers
from app.core.logging import configure_logging, get_logger


@asynccontextmanager
async def lifespan(app: FastAPI):
    configure_logging()
    log = get_logger("startup")
    settings = get_settings()
    log.info("backend_starting", env=settings.environment, version=__version__)
    # Under an ASGI server (uvicorn) the app is imported inside a running loop, so
    # the import-time bootstrap is skipped — initialise the DB here instead.
    from app.db.session import init_db

    await init_db()
    yield
    log.info("backend_stopping")


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title=settings.app_name,
        version=__version__,
        description=(
            "Cloud-native AI backend for the IDBI Wealth AI SDK: authentication, "
            "banking APIs, AI orchestration, recommendations, portfolio, spending, "
            "goals, fraud, and notifications."
        ),
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Middleware runs in reverse add-order: rate limiter added last → runs first.
    if settings.security_headers_enabled:
        from app.core.security_middleware import SecurityHeadersMiddleware

        app.add_middleware(SecurityHeadersMiddleware, hsts=settings.hsts_enabled)
    if settings.rate_limit_enabled:
        from app.core.security_middleware import RateLimitMiddleware

        app.add_middleware(
            RateLimitMiddleware,
            limit=settings.rate_limit_requests,
            window_seconds=settings.rate_limit_window_seconds,
        )

    # Added last → runs outermost, times the full request including all middleware.
    from app.core.observability import RequestObservabilityMiddleware

    app.add_middleware(RequestObservabilityMiddleware)

    # Fail fast on insecure production config; warn otherwise.
    from app.core.security_audit import enforce_security

    enforce_security(settings)

    register_exception_handlers(app)
    app.include_router(api_router, prefix=settings.api_v1_prefix)

    @app.get("/", tags=["system"], summary="Root")
    async def root() -> dict[str, str]:
        return {
            "service": settings.app_name,
            "version": __version__,
            "docs": "/docs",
        }

    return app


def _bootstrap_database() -> None:
    """Eagerly create schema + seed demo data when no event loop is running.

    The sync `TestClient` doesn't run ASGI lifespan events, so we initialise the
    DB at import for tests. Under uvicorn the import happens inside a running
    loop — we detect that and skip here, letting the lifespan handler do it.
    """
    import asyncio

    from app.db.session import init_db

    try:
        asyncio.get_running_loop()
        return  # a loop is already running (uvicorn) → lifespan will init
    except RuntimeError:
        pass
    asyncio.run(init_db())


_bootstrap_database()
app = create_app()
