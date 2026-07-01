"""Pydantic schemas for the Goal Planner endpoints."""
from __future__ import annotations

from datetime import date

from pydantic import BaseModel, Field

from app.models.goal import GoalCategory
from app.schemas.banking import ExplanationOut


class GoalOut(BaseModel):
    id: str
    name: str
    category: GoalCategory
    target_amount: float
    current_amount: float
    target_date: date
    monthly_contribution: float
    expected_return_rate: float
    # Computed projections:
    progress_pct: float          # current / target, 0–100
    months_remaining: int
    required_monthly: float       # SIP needed to hit the target exactly
    projected_value: float        # FV at the current contribution
    on_track: bool
    surplus_or_shortfall: float   # projected - target


class CreateGoalRequest(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    target_amount: float = Field(gt=0)
    target_date: date
    current_amount: float = Field(default=0, ge=0)
    monthly_contribution: float = Field(default=0, ge=0)
    expected_return_rate: float = Field(default=0.10, ge=0, le=0.5)
    category: GoalCategory = GoalCategory.other


class UpdateGoalRequest(BaseModel):
    target_amount: float | None = Field(default=None, gt=0)
    current_amount: float | None = Field(default=None, ge=0)
    monthly_contribution: float | None = Field(default=None, ge=0)
    target_date: date | None = None
    expected_return_rate: float | None = Field(default=None, ge=0, le=0.5)


class SimulateRequest(BaseModel):
    target_amount: float = Field(gt=0)
    target_date: date
    current_amount: float = Field(default=0, ge=0)
    monthly_contribution: float | None = Field(default=None, ge=0)
    expected_return_rate: float = Field(default=0.10, ge=0, le=0.5)


class SimulateResponse(BaseModel):
    target_amount: float
    months: int
    required_monthly: float           # to reach target exactly
    projected_value: float | None     # FV if a monthly_contribution was given
    on_track: bool                    # only meaningful when monthly given
    insight: ExplanationOut


class MessageResponse(BaseModel):
    message: str
