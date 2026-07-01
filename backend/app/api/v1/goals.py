"""Goal Planner endpoints (`/api/v1/goals`)."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status

from app.core.dependencies import CurrentUser
from app.repositories.goal_repository import GoalRepository, get_goal_repository
from app.schemas.goals import (
    CreateGoalRequest,
    GoalOut,
    MessageResponse,
    SimulateRequest,
    SimulateResponse,
    UpdateGoalRequest,
)
from app.services.goal_service import GoalService

router = APIRouter(prefix="/goals", tags=["goals"])


def get_goal_service(
    goals: Annotated[GoalRepository, Depends(get_goal_repository)],
) -> GoalService:
    return GoalService(goals)


GoalDep = Annotated[GoalService, Depends(get_goal_service)]


@router.get("", response_model=list[GoalOut], summary="List goals with projections")
async def list_goals(user: CurrentUser, service: GoalDep) -> list[GoalOut]:
    return await service.list_goals(user)


@router.post(
    "",
    response_model=GoalOut,
    status_code=status.HTTP_201_CREATED,
    summary="Create a goal",
)
async def create_goal(
    req: CreateGoalRequest, user: CurrentUser, service: GoalDep
) -> GoalOut:
    return await service.create_goal(user, req)


@router.post(
    "/simulate",
    response_model=SimulateResponse,
    summary="Simulate the SIP needed to reach a target (without saving a goal)",
)
async def simulate(
    req: SimulateRequest, user: CurrentUser, service: GoalDep
) -> SimulateResponse:
    return service.simulate(req)


@router.get("/{goal_id}", response_model=GoalOut, summary="Fetch one goal")
async def get_goal(goal_id: str, user: CurrentUser, service: GoalDep) -> GoalOut:
    return await service.get_goal(user, goal_id)


@router.patch("/{goal_id}", response_model=GoalOut, summary="Update a goal")
async def update_goal(
    goal_id: str, req: UpdateGoalRequest, user: CurrentUser, service: GoalDep
) -> GoalOut:
    return await service.update_goal(user, goal_id, req)


@router.delete(
    "/{goal_id}", response_model=MessageResponse, summary="Delete a goal"
)
async def delete_goal(
    goal_id: str, user: CurrentUser, service: GoalDep
) -> MessageResponse:
    await service.delete_goal(user, goal_id)
    return MessageResponse(message="Goal deleted.")
