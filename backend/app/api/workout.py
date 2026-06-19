from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
import json
from app.db.base import get_db
from app.models.user import User
from app.models.workout import Exercise, WorkoutPlan, WorkoutSession, SessionExercise, MuscleGroup
from app.api.auth import get_current_user
import httpx
from app.config import settings
from fastapi.responses import StreamingResponse

router = APIRouter(prefix="/workout", tags=["Workout"])

# Split templates based on days/week
SPLIT_TEMPLATES = {
    2: [
        {"day": 0, "focus": "Full Body A", "muscles": [MuscleGroup.chest, MuscleGroup.back, MuscleGroup.legs]},
        {"day": 3, "focus": "Full Body B", "muscles": [MuscleGroup.shoulders, MuscleGroup.biceps, MuscleGroup.triceps, MuscleGroup.core]},
    ],
    3: [
        {"day": 0, "focus": "Push", "muscles": [MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.triceps]},
        {"day": 2, "focus": "Pull", "muscles": [MuscleGroup.back, MuscleGroup.biceps]},
        {"day": 4, "focus": "Legs", "muscles": [MuscleGroup.legs, MuscleGroup.glutes, MuscleGroup.core]},
    ],
    4: [
        {"day": 0, "focus": "Upper A", "muscles": [MuscleGroup.chest, MuscleGroup.back]},
        {"day": 1, "focus": "Lower A", "muscles": [MuscleGroup.legs, MuscleGroup.glutes]},
        {"day": 3, "focus": "Upper B", "muscles": [MuscleGroup.shoulders, MuscleGroup.biceps, MuscleGroup.triceps]},
        {"day": 4, "focus": "Lower B", "muscles": [MuscleGroup.legs, MuscleGroup.core]},
    ],
    5: [
        {"day": 0, "focus": "Chest & Triceps", "muscles": [MuscleGroup.chest, MuscleGroup.triceps]},
        {"day": 1, "focus": "Back & Biceps", "muscles": [MuscleGroup.back, MuscleGroup.biceps]},
        {"day": 2, "focus": "Legs", "muscles": [MuscleGroup.legs, MuscleGroup.glutes]},
        {"day": 3, "focus": "Shoulders & Arms", "muscles": [MuscleGroup.shoulders, MuscleGroup.biceps, MuscleGroup.triceps]},
        {"day": 4, "focus": "Full Body & Core", "muscles": [MuscleGroup.chest, MuscleGroup.back, MuscleGroup.core]},
    ],
}

def get_sets_reps(goal: str, is_compound: bool) -> tuple:
    """Return (sets, reps, rest) based on goal"""
    if goal == "muscle_gain":
        return (4, "8-12", 90) if is_compound else (3, "12-15", 60)
    elif goal == "weight_loss":
        return (3, "15-20", 45) if not is_compound else (3, "12-15", 60)
    elif goal == "endurance":
        return (3, "20-25", 30)
    else:  # general_fitness
        return (3, "10-15", 60)

def get_exercises_for_muscle(
    db: Session,
    muscle: MuscleGroup,
    difficulty: str,
    limit: int = 2,
    injuries: list = []
) -> list:
    """Fetch best exercises for a muscle group filtered by difficulty"""
    difficulty_map = {
        "beginner": ["beginner"],
        "intermediate": ["beginner", "intermediate"],
        "advanced": ["beginner", "intermediate", "advanced"]
    }
    allowed = difficulty_map.get(difficulty, ["beginner"])

    exercises = (
        db.query(Exercise)
        .filter(
            Exercise.muscle_group == muscle,
            Exercise.difficulty.in_(allowed)
        )
        .order_by(Exercise.hypertrophy_score.desc())
        .limit(limit)
        .all()
    )
    return exercises

@router.post("/generate")
def generate_workout_plan(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Validate user has profile
    if not current_user.fitness_goal:
        raise HTTPException(
            status_code=400,
            detail="Please complete your fitness profile first via PUT /users/profile"
        )

    days = current_user.days_per_week or 3
    goal = current_user.fitness_goal.value
    experience = current_user.experience_level.value if current_user.experience_level else "beginner"
    injuries = json.loads(current_user.injuries) if current_user.injuries else []

    # Deactivate old plans
    db.query(WorkoutPlan).filter(
        WorkoutPlan.user_id == current_user.id,
        WorkoutPlan.is_active == True
    ).update({"is_active": False})

    # Get closest template
    available_days = sorted(SPLIT_TEMPLATES.keys())
    chosen_days = min(available_days, key=lambda x: abs(x - days))
    template = SPLIT_TEMPLATES[chosen_days]

    # Create plan
    plan = WorkoutPlan(
        user_id=current_user.id,
        name=f"{goal.replace('_', ' ').title()} Plan - Week 1",
        week_number=1,
        is_active=True,
        ai_generated=True,
        notes=f"Auto-generated for {experience} level, {days} days/week"
    )
    db.add(plan)
    db.flush()

    result_sessions = []

    for template_day in template:
        session = WorkoutSession(
            plan_id=plan.id,
            day_of_week=template_day["day"],
            focus=template_day["focus"],
            duration_mins=current_user.workout_duration_mins or 45
        )
        db.add(session)
        db.flush()

        session_exercises = []
        order = 0

        for muscle in template_day["muscles"]:
            limit = 2 if len(template_day["muscles"]) > 2 else 3
            exercises = get_exercises_for_muscle(db, muscle, experience, limit, injuries)

            for ex in exercises:
                sets, reps, rest = get_sets_reps(goal, ex.is_compound)
                se = SessionExercise(
                    session_id=session.id,
                    exercise_id=ex.id,
                    sets=sets,
                    reps=reps,
                    rest_seconds=rest,
                    order_index=order
                )
                db.add(se)
                order += 1
                session_exercises.append({
                    "name": ex.name,
                    "muscle_group": ex.muscle_group.value,
                    "sets": sets,
                    "reps": reps,
                    "rest_seconds": rest,
                    "instructions": ex.instructions,
                    "is_compound": ex.is_compound
                })

        result_sessions.append({
            "day_of_week": template_day["day"],
            "focus": template_day["focus"],
            "exercises": session_exercises
        })

    db.commit()

    return {
        "message": "Workout plan generated successfully!",
        "plan_id": plan.id,
        "goal": goal,
        "experience_level": experience,
        "days_per_week": chosen_days,
        "sessions": result_sessions
    }

@router.get("/plan")
def get_active_plan(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    plan = db.query(WorkoutPlan).filter(
        WorkoutPlan.user_id == current_user.id,
        WorkoutPlan.is_active == True
    ).first()

    if not plan:
        raise HTTPException(status_code=404, detail="No active workout plan found. Generate one first.")

    sessions = []
    for session in plan.sessions:
        exercises = []
        for se in sorted(session.exercises, key=lambda x: x.order_index):
            ex = db.query(Exercise).filter(Exercise.id == se.exercise_id).first()
            exercises.append({
                "name": ex.name,
                "muscle_group": ex.muscle_group.value,
                "sets": se.sets,
                "reps": se.reps,
                "rest_seconds": se.rest_seconds,
                "instructions": ex.instructions
            })
        sessions.append({
            "day_of_week": session.day_of_week,
            "focus": session.focus,
            "duration_mins": session.duration_mins,
            "exercises": exercises
        })

    return {
        "plan_id": plan.id,
        "name": plan.name,
        "week_number": plan.week_number,
        "sessions": sessions
    }


@router.get("/exercise-gif/{exercise_name}")
async def get_exercise_gif(exercise_name: str):
    try:
        async with httpx.AsyncClient() as client:
            res = await client.get(
                "https://oss.exercisedb.dev/api/v1/exercises",
                params={"name": exercise_name.lower(), "limit": 10},
                timeout=10.0,
            )
            if res.status_code == 200:
                body      = res.json()
                exercises = body.get("data", [])

                if exercises:
                    search = exercise_name.lower().strip()

                    def score(ex):
                        name = ex.get("name", "").lower()
                        # Exact match = highest score
                        if name == search:                    return 100
                        # Search term fully inside result name
                        if search in name:                    return 80
                        # Result name fully inside search term
                        if name in search:                    return 70
                        # Count matching words
                        s_words = set(search.split())
                        n_words = set(name.split())
                        common  = len(s_words & n_words)
                        return common * 10

                    matched = max(exercises, key=score)
                    gif_url = matched.get("gifUrl", "")
                    print(f"✅ Matched: '{matched.get('name')}' for '{search}' → {gif_url}")

                    return {
                        "gif_url":     gif_url,
                        "instructions":matched.get("instructions", []),
                        "target":      matched.get("targetMuscles",
                                         [matched.get("target", "")]),
                        "secondary":   matched.get("secondaryMuscles", []),
                        "equipment":   matched.get("equipments",
                                         [matched.get("equipment", "")]),
                        "difficulty":  matched.get("difficulty", ""),
                        "description": matched.get("description", ""),
                        "body_part":   matched.get("bodyParts",
                                         [matched.get("bodyPart", "")]),
                    }
    except Exception as e:
        print(f"❌ Error: {e}")
    return {"gif_url": "", "instructions": [], "target": "", "equipment": ""}

@router.get("/exercise-gif-image")
async def proxy_gif(url: str):
    """Proxy GIF to avoid CORS issues on Flutter Web"""
    try:
        async with httpx.AsyncClient() as client:
            res = await client.get(url, timeout=15.0, follow_redirects=True)
            if res.status_code == 200:
                return StreamingResponse(
                    iter([res.content]),
                    media_type="image/gif",
                    headers={"Cache-Control": "public, max-age=86400"},
                )
    except Exception as e:
        print(f"❌ GIF proxy error: {e}")
    from fastapi import HTTPException
    raise HTTPException(status_code=404, detail="GIF not found")