from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base

class FoodItem(Base):
    __tablename__ = "food_items"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    name_hindi = Column(String, nullable=True)
    category = Column(String, nullable=True)        # "dal", "sabzi", "dairy" etc
    region = Column(String, nullable=True)          # "north", "south", "west", "east"
    calories_per_100g = Column(Float, nullable=False)
    protein_per_100g = Column(Float, nullable=False)
    carbs_per_100g = Column(Float, nullable=False)
    fats_per_100g = Column(Float, nullable=False)
    fiber_per_100g = Column(Float, default=0.0)
    is_vegetarian = Column(Boolean, default=True)
    is_vegan = Column(Boolean, default=False)
    avg_price_per_100g_inr = Column(Float, nullable=True)
    is_hostel_friendly = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class DietPlan(Base):
    __tablename__ = "diet_plans"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    daily_calories = Column(Float, nullable=False)
    daily_protein_g = Column(Float, nullable=False)
    daily_carbs_g = Column(Float, nullable=False)
    daily_fats_g = Column(Float, nullable=False)
    budget_per_day_inr = Column(Float, nullable=True)
    is_active = Column(Boolean, default=True)
    ai_generated = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="diet_plans")
    meals = relationship("Meal", back_populates="diet_plan")

class Meal(Base):
    __tablename__ = "meals"

    id = Column(Integer, primary_key=True, index=True)
    diet_plan_id = Column(Integer, ForeignKey("diet_plans.id"), nullable=False)
    meal_type = Column(String, nullable=False)   # "breakfast", "lunch", "dinner", "snack"
    day_of_week = Column(Integer, nullable=True)
    total_calories = Column(Float, default=0)
    total_protein_g = Column(Float, default=0)
    notes = Column(Text, nullable=True)

    diet_plan = relationship("DietPlan", back_populates="meals")
    items = relationship("MealItem", back_populates="meal")

class MealItem(Base):
    __tablename__ = "meal_items"

    id = Column(Integer, primary_key=True, index=True)
    meal_id = Column(Integer, ForeignKey("meals.id"), nullable=False)
    food_item_id = Column(Integer, ForeignKey("food_items.id"), nullable=False)
    quantity_g = Column(Float, nullable=False)
    meal = relationship("Meal", back_populates="items")