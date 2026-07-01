"""Fraud Detection domain models.

Alerts are computed on the fly by the fraud engine, not persisted.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from enum import Enum


class FraudAlertType(str, Enum):
    unusual_amount = "unusual_amount"
    duplicate_charge = "duplicate_charge"
    new_merchant_high_value = "new_merchant_high_value"


class FraudRiskLevel(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"


@dataclass
class FraudAlert:
    id: str
    type: FraudAlertType
    risk_level: FraudRiskLevel
    merchant: str
    amount: float
    date: date
    reason: str
