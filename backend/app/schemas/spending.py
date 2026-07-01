"""Pydantic schemas for the Spending Analytics endpoints."""
from __future__ import annotations

from datetime import date

from pydantic import BaseModel, Field

from app.models.spending import SpendCategory, TransactionDirection
from app.schemas.banking import ExplanationOut


class TransactionOut(BaseModel):
    id: str
    date: date
    merchant: str
    amount: float
    direction: TransactionDirection
    category: SpendCategory


class CategorySpendOut(BaseModel):
    category: SpendCategory
    amount: float
    percentage: float  # share of total spend, 0–100


class SpendingSummaryOut(BaseModel):
    month: str  # "YYYY-MM"
    total_spent: float
    total_income: float
    net: float
    previous_month_spent: float
    change_pct: float  # spend change vs previous month, +/-%
    categories: list[CategorySpendOut]
    top_merchants: list[str]
    insight: ExplanationOut


class TransactionsPageOut(BaseModel):
    items: list[TransactionOut]
    total: int


class BudgetOut(BaseModel):
    category: SpendCategory
    monthly_limit: float
    spent: float
    remaining: float
    used_pct: float
    status: str  # under | near | over


class SetBudgetRequest(BaseModel):
    monthly_limit: float = Field(gt=0, le=10_000_000)
