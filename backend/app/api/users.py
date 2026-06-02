from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from app.db.base import get_db
from app.models.user import User, FitnessGoal, ExperienceLevel
from app.api.auth import get_current_user

router = APIRouter(prefix="/users", tags=["Users"])

class ProfileUpdateRequest(BaseModel):
    age: Optional[int] = None
    gender: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    target_weight_kg: Optional[float] = None
    fitness_goal: Optional[FitnessGoal] = None
    experience_level: Optional[ExperienceLevel] = None
    days_per_week: Optional[int] = None
    workout_duration_mins: Optional[int] = None
    is_vegetarian: Optional[bool] = None
    monthly_food_budget: Optional[float] = None
    injuries: Optional[str] = None
    preferred_language: Optional[str] = None
    is_elderly: Optional[bool] = None
    is_differently_abled: Optional[bool] = None

@router.put("/profile")
def update_profile(
    data: ProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(current_user, field, value)
    db.commit()
    db.refresh(current_user)
    return {"message": "Profile updated successfully", "user_id": current_user.id}

@router.get("/profile")
def get_profile(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "full_name": current_user.full_name,
        "email": current_user.email,
        "age": current_user.age,
        "gender": current_user.gender,
        "height_cm": current_user.height_cm,
        "weight_kg": current_user.weight_kg,
        "fitness_goal": current_user.fitness_goal,
        "experience_level": current_user.experience_level,
        "days_per_week": current_user.days_per_week,
        "workout_duration_mins": current_user.workout_duration_mins,
        "is_vegetarian": current_user.is_vegetarian,
        "monthly_food_budget": current_user.monthly_food_budget,
        "injuries": current_user.injuries,
        "is_premium": current_user.is_premium
    }