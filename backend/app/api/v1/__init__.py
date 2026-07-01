"""Versioned API v1 router aggregation.

Domain routers (auth, banking, spending, goals, health, recommendations,
portfolio, fraud, predictive, notifications, chat) are mounted here as they are
implemented in their respective modules.
"""
from fastapi import APIRouter

from app.api.v1 import (
    ai,
    analytics,
    auth,
    avatar,
    banking,
    chat,
    financial_health,
    fraud,
    goals,
    health,
    monitoring,
    notifications,
    portfolio,
    predictive,
    profile,
    rag,
    recommendations,
    spending,
    voice,
)

api_router = APIRouter()
api_router.include_router(health.router, tags=["system"])
api_router.include_router(monitoring.router)
api_router.include_router(analytics.router)
api_router.include_router(ai.router)
api_router.include_router(rag.router)
api_router.include_router(auth.router)
api_router.include_router(banking.router)
api_router.include_router(chat.router)
api_router.include_router(avatar.router)
api_router.include_router(voice.router)
api_router.include_router(spending.router)
api_router.include_router(financial_health.router)
api_router.include_router(goals.router)
api_router.include_router(recommendations.router)
api_router.include_router(portfolio.router)
api_router.include_router(predictive.router)
api_router.include_router(fraud.router)
api_router.include_router(notifications.router)
api_router.include_router(profile.router)
