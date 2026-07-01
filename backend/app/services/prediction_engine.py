"""Pure predictive-banking engine.

Detects recurring cashflows from transaction history and projects them forward to
produce predictions: the next salary credit, upcoming bills/EMIs, a low-balance
warning (by simulating the balance to the next pay-day), and a seasonal tax
reminder. Deterministic and side-effect-free; the service supplies the inputs.
"""
from __future__ import annotations

from collections import defaultdict
from datetime import date

from app.models.prediction import (
    Prediction,
    PredictionSeverity,
    PredictionType,
    RecurringItem,
)
from app.models.spending import Transaction, TransactionDirection
from app.services.goal_math import add_months

LOW_BALANCE_THRESHOLD = 25_000.0
_HORIZON_DAYS = 35


def detect_recurring(transactions: list[Transaction]) -> list[RecurringItem]:
    """Merchants seen in ≥2 distinct months are treated as recurring."""
    by_merchant: dict[str, list[Transaction]] = defaultdict(list)
    for t in transactions:
        by_merchant[t.merchant].append(t)

    items: list[RecurringItem] = []
    for merchant, txns in by_merchant.items():
        months = {(t.date.year, t.date.month) for t in txns}
        if len(months) < 2:
            continue
        avg_amount = sum(t.amount for t in txns) / len(txns)
        # Most common day-of-month.
        day = max(
            {t.date.day for t in txns},
            key=lambda d: sum(1 for t in txns if t.date.day == d),
        )
        first = txns[0]
        items.append(
            RecurringItem(
                label=merchant,
                amount=round(avg_amount, 2),
                direction=first.direction,
                day=day,
                category=first.category,
            )
        )
    return items


def _next_occurrence(day: int, today: date) -> date:
    """The next date on day-of-month [day], today or later."""
    safe_day = min(day, 28)
    candidate = date(today.year, today.month, safe_day)
    if candidate < today:
        candidate = add_months(candidate, 1)
    return candidate


def build_predictions(
    liquid_balance: float,
    recurring: list[RecurringItem],
    today: date,
    *,
    threshold: float = LOW_BALANCE_THRESHOLD,
) -> list[Prediction]:
    predictions: list[Prediction] = []
    horizon = add_months(today, 0)  # copy
    # Upcoming occurrences within the horizon.
    upcoming: list[tuple[date, RecurringItem]] = []
    for item in recurring:
        when = _next_occurrence(item.day, today)
        if (when - today).days <= _HORIZON_DAYS:
            upcoming.append((when, item))
    upcoming.sort(key=lambda pair: pair[0])

    # Next salary credit.
    next_salary: date | None = None
    for when, item in upcoming:
        if item.direction == TransactionDirection.credit:
            next_salary = when
            predictions.append(Prediction(
                type=PredictionType.salary_credit,
                title="Salary expected",
                message=f"Your salary of ₹{item.amount:,.0f} is expected around this date.",
                predicted_date=when,
                severity=PredictionSeverity.info,
                days_away=(when - today).days,
                amount=item.amount,
            ))
            break

    # Upcoming debits (bills + EMIs).
    for when, item in upcoming:
        if item.direction != TransactionDirection.debit:
            continue
        is_emi = item.is_loan
        predictions.append(Prediction(
            type=PredictionType.emi_due if is_emi else PredictionType.bill_due,
            title=f"{'EMI' if is_emi else 'Bill'} due: {item.label}",
            message=f"₹{item.amount:,.0f} for {item.label} is due around this date.",
            predicted_date=when,
            severity=PredictionSeverity.warning if is_emi else PredictionSeverity.info,
            days_away=(when - today).days,
            amount=item.amount,
        ))

    # Low-balance simulation: run the balance down through debits until the next
    # salary lands; warn if it dips below the threshold.
    balance = liquid_balance
    cutoff = next_salary or add_months(today, 1)
    running_min = balance
    dip_date: date | None = None
    for when, item in upcoming:
        if when >= cutoff:
            continue
        if item.direction == TransactionDirection.debit:
            balance -= item.amount
            if balance < running_min:
                running_min = balance
                if balance < threshold and dip_date is None:
                    dip_date = when
    if dip_date is not None:
        predictions.append(Prediction(
            type=PredictionType.low_balance,
            title="Low balance ahead",
            message=(
                f"Your balance may fall to about ₹{running_min:,.0f} before your next "
                "salary — consider holding back on big spends."
            ),
            predicted_date=dip_date,
            severity=PredictionSeverity.critical if running_min < 0 else PredictionSeverity.warning,
            days_away=(dip_date - today).days,
            amount=round(running_min, 2),
        ))

    # Seasonal tax reminder (always present so guidance is timely year-round).
    predictions.append(_tax_reminder(today, horizon))

    predictions.sort(key=lambda p: p.predicted_date)
    return predictions


def project_month_end_balance(
    liquid_balance: float, recurring: list[RecurringItem], today: date
) -> float:
    """Projected liquid balance at month end from upcoming recurring flows."""
    last_day = add_months(date(today.year, today.month, 1), 1)
    balance = liquid_balance
    for item in recurring:
        when = _next_occurrence(item.day, today)
        if when < last_day:
            if item.direction == TransactionDirection.credit:
                balance += item.amount
            else:
                balance -= item.amount
    return round(balance, 2)


def _tax_reminder(today: date, _horizon: date) -> Prediction:
    month = today.month
    if month in (1, 2, 3):
        msg = "Complete your 80C investments before March 31 to save tax this year."
        when = date(today.year, 3, 28)
    elif month == 6:
        msg = "First advance-tax installment (15%) is due by June 15."
        when = date(today.year, 6, 15)
    elif month == 9:
        msg = "Second advance-tax installment (45%) is due by September 15."
        when = date(today.year, 9, 15)
    elif month == 12:
        msg = "Third advance-tax installment (75%) is due by December 15."
        when = date(today.year, 12, 15)
    else:
        msg = "Keep your investment and expense proofs handy for tax season."
        when = add_months(today, 1)
    # If the seasonal deadline has already passed this month, give generic guidance.
    if when < today:
        msg = "Keep your investment and expense proofs handy for tax season."
        when = add_months(today, 1)
    return Prediction(
        type=PredictionType.tax_reminder,
        title="Tax reminder",
        message=msg,
        predicted_date=when,
        severity=PredictionSeverity.info,
        days_away=(when - today).days,
        amount=None,
    )
