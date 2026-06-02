from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base
import enum

class FitnessGoal(str, enum.Enum):
    weight_loss = "weight_loss"
    muscle_gain = "muscle_gain"
    endurance = "endurance"
    general_fitness = "general_fitness"
    rehabilitation = "rehabilitation"

class ExperienceLevel(str, enum.Enum):
    beginner = "beginner"
    intermediate = "intermediate"
    advanced = "advanced"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    phone = Column(String, unique=True, nullable=True)
    full_name = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)

    # Physical profile
    age = Column(Integer, nullable=True)
    gender = Column(String, nullable=True)
    height_cm = Column(Float, nullable=True)
    weight_kg = Column(Float, nullable=True)
    target_weight_kg = Column(Float, nullable=True)

    # Fitness profile
    fitness_goal = Column(Enum(FitnessGoal), nullable=True)
    experience_level = Column(Enum(ExperienceLevel), default=ExperienceLevel.beginner)
    days_per_week = Column(Integer, default=3)
    workout_duration_mins = Column(Integer, default=45)

    # Preferences
    preferred_language = Column(String, default="en")
    is_vegetarian = Column(Boolean, default=False)
    monthly_food_budget = Column(Float, nullable=True)  # INR

    # Health
    injuries = Column(String, nullable=True)  # JSON string
    medical_conditions = Column(String, nullable=True)

    # Inclusion modes
    is_elderly = Column(Boolean, default=False)
    is_differently_abled = Column(Boolean, default=False)

    # Meta
    is_active = Column(Boolean, default=True)
    is_premium = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    workouts = relationship("WorkoutPlan", back_populates="user")
    diet_plans = relationship("DietPlan", back_populates="user")
    progress_logs = relationship("ProgressLog", back_populates="user")
    recovery_logs = relationship("RecoveryLog", back_populates="user")