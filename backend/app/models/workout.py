from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base
import enum

class MuscleGroup(str, enum.Enum):
    chest = "chest"
    back = "back"
    shoulders = "shoulders"
    biceps = "biceps"
    triceps = "triceps"
    legs = "legs"
    glutes = "glutes"
    core = "core"
    full_body = "full_body"

class Exercise(Base):
    __tablename__ = "exercises"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    muscle_group = Column(Enum(MuscleGroup), nullable=False)
    equipment_needed = Column(String, nullable=True)  # "barbell, bench" etc
    difficulty = Column(String, default="beginner")
    instructions = Column(Text, nullable=True)
    video_url = Column(String, nullable=True)
    hypertrophy_score = Column(Float, default=5.0)  # 1-10 research score
    injury_risk = Column(Float, default=3.0)         # 1-10
    is_compound = Column(Boolean, default=False)
    substitutes = Column(String, nullable=True)      # JSON: list of exercise IDs
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class WorkoutPlan(Base):
    __tablename__ = "workout_plans"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    week_number = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    ai_generated = Column(Boolean, default=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="workouts")
    sessions = relationship("WorkoutSession", back_populates="plan")

class WorkoutSession(Base):
    __tablename__ = "workout_sessions"

    id = Column(Integer, primary_key=True, index=True)
    plan_id = Column(Integer, ForeignKey("workout_plans.id"), nullable=False)
    day_of_week = Column(Integer, nullable=False)  # 0=Mon, 6=Sun
    focus = Column(String, nullable=True)          # "Push", "Pull", "Legs"
    duration_mins = Column(Integer, default=45)
    completed = Column(Boolean, default=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)

    plan = relationship("WorkoutPlan", back_populates="sessions")
    exercises = relationship("SessionExercise", back_populates="session")

class SessionExercise(Base):
    __tablename__ = "session_exercises"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("workout_sessions.id"), nullable=False)
    exercise_id = Column(Integer, ForeignKey("exercises.id"), nullable=False)
    sets = Column(Integer, default=3)
    reps = Column(String, default="8-12")   # e.g. "8-12" or "AMRAP"
    rest_seconds = Column(Integer, default=90)
    weight_kg = Column(Float, nullable=True)
    rpe = Column(Float, nullable=True)       # Rate of Perceived Exertion 1-10
    order_index = Column(Integer, default=0)

    session = relationship("WorkoutSession", back_populates="exercises")