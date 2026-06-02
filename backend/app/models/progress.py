from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base

class ProgressLog(Base):
    __tablename__ = "progress_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    weight_kg = Column(Float, nullable=True)
    body_fat_pct = Column(Float, nullable=True)
    chest_cm = Column(Float, nullable=True)
    waist_cm = Column(Float, nullable=True)
    hips_cm = Column(Float, nullable=True)
    arms_cm = Column(Float, nullable=True)
    notes = Column(Text, nullable=True)
    logged_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="progress_logs")

class RecoveryLog(Base):
    __tablename__ = "recovery_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    sleep_hours = Column(Float, nullable=True)
    sleep_quality = Column(Integer, nullable=True)   # 1-5
    soreness_level = Column(Integer, nullable=True)  # 1-5
    stress_level = Column(Integer, nullable=True)    # 1-5
    energy_level = Column(Integer, nullable=True)    # 1-5
    is_pain = Column(Boolean, default=False)         # pain vs soreness
    pain_location = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    ai_recommendation = Column(Text, nullable=True)
    logged_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="recovery_logs")