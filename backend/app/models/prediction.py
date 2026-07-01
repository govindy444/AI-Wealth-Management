"""Predictive Banking domain models.

Predictions are computed on the fly by the prediction engine, not persisted.
`RecurringItem` is the intermediate the engine projects forward.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from enum import Enum

from app.models.spending import SpendCategory, TransactionDirection


class PredictionType(str, Enum):
    salary_credit = "salary_credit"
    bill_due = "bill_due"
    emi_due = "emi_due"
    low_balance = "low_balance"
    tax_reminder = "tax_reminder"


class PredictionSeverity(str, Enum):
    info = "info"
    warning = "warning"
    critical = "critical"


@dataclass
class RecurringItem:
    """A detected recurring cashflow (salary, rent, EMI, subscription…)."""

    label: str
    amount: float
    direction: TransactionDirection
    day: int  # day-of-month it typically occurs
    category: SpendCategory
    is_loan: bool = False


@dataclass
class Prediction:
    type: PredictionType
    title: str
    message: str
    predicted_date: date
    severity: PredictionSeverity
    days_away: int
    amount: float | None = None
