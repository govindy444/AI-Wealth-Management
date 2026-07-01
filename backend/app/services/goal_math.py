"""Pure goal/SIP financial math.

Deterministic, side-effect-free time-value-of-money helpers so goal projections
are exact and trivially testable. Used by the Goal Planner service; no LLM is
involved in the maths (Module 21 only adds narrative around these numbers).
"""
from __future__ import annotations

from datetime import date


def add_months(start: date, months: int) -> date:
    """Returns [start] shifted by [months], clamping the day to month length."""
    total = (start.year * 12 + (start.month - 1)) + months
    year, month = divmod(total, 12)
    month += 1
    # Clamp day (e.g. Jan 31 + 1mo → Feb 28).
    day = min(start.day, [31, 29 if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
                          else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1])
    return date(year, month, day)


def months_between(start: date, end: date) -> int:
    """Whole months from [start] to [end] (never negative)."""
    months = (end.year - start.year) * 12 + (end.month - start.month)
    if end.day < start.day:
        months -= 1
    return max(0, months)


def future_value(present: float, monthly: float, annual_rate: float, months: int) -> float:
    """FV of a lump sum [present] plus a monthly contribution over [months]."""
    if months <= 0:
        return present
    r = annual_rate / 12
    fv_present = present * (1 + r) ** months
    if r == 0:
        fv_contrib = monthly * months
    else:
        fv_contrib = monthly * (((1 + r) ** months - 1) / r)
    return fv_present + fv_contrib


def required_monthly(target: float, present: float, annual_rate: float, months: int) -> float:
    """Monthly contribution needed to reach [target] in [months]."""
    r = annual_rate / 12
    fv_present = present * (1 + r) ** months if months > 0 else present
    needed = max(0.0, target - fv_present)
    if months <= 0:
        return needed
    if r == 0:
        return needed / months
    factor = ((1 + r) ** months - 1) / r
    return needed / factor
