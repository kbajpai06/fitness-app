from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from groq import Groq
from app.db.base import get_db
from app.models.user import User
from app.models.workout import WorkoutPlan, WorkoutSession, SessionExercise, Exercise
from app.models.diet import DietPlan, Meal, MealItem, FoodItem
from app.models.progress import RecoveryLog
from app.api.auth import get_current_user
from app.config import settings

router = APIRouter(prefix="/coach", tags=["AI Coach"])

# ── Groq Client ───────────────────────────────────────────────────────────────

def get_groq_client():
    if not settings.GROQ_API_KEY:
        raise HTTPException(500, "GROQ_API_KEY not set in .env")
    return Groq(api_key=settings.GROQ_API_KEY)

# ── Build User Context for AI ─────────────────────────────────────────────────

def build_user_context(user: User, db: Session) -> str:
    """Build a rich context string about the user for the AI"""

    lines = [
        f"USER PROFILE:",
        f"- Name: {user.full_name}",
        f"- Age: {user.age or 'not set'}, Gender: {user.gender or 'not set'}",
        f"- Weight: {user.weight_kg or 'not set'} kg, Height: {user.height_cm or 'not set'} cm",
        f"- Fitness Goal: {user.fitness_goal.value if user.fitness_goal else 'not set'}",
        f"- Experience Level: {user.experience_level.value if user.experience_level else 'beginner'}",
        f"- Workout Days/Week: {user.days_per_week or 3}",
        f"- Vegetarian: {'Yes' if user.is_vegetarian else 'No'}",
        f"- Monthly Food Budget: ₹{user.monthly_food_budget or 'not set'}",
        f"- Injuries: {user.injuries or 'None reported'}",
        f"- Preferred Language: {user.preferred_language or 'English'}",
    ]

    # Active workout plan
    plan = db.query(WorkoutPlan).filter(
        WorkoutPlan.user_id == user.id,
        WorkoutPlan.is_active == True
    ).first()

    if plan:
        lines.append(f"\nCURRENT WORKOUT PLAN: {plan.name}")
        for session in plan.sessions:
            exercise_names = []
            for se in session.exercises:
                ex = db.query(Exercise).filter(Exercise.id == se.exercise_id).first()
                if ex:
                    exercise_names.append(f"{ex.name} ({se.sets}x{se.reps})")
            lines.append(
                f"- Day {session.day_of_week + 1} [{session.focus}]: "
                f"{', '.join(exercise_names[:4])}{'...' if len(exercise_names) > 4 else ''}"
            )
    else:
        lines.append("\nWORKOUT PLAN: Not generated yet")

    # Active diet plan
    diet = db.query(DietPlan).filter(
        DietPlan.user_id == user.id,
        DietPlan.is_active == True
    ).first()

    if diet:
        lines.append(
            f"\nDIET PLAN: {round(diet.daily_calories)} kcal/day | "
            f"Protein: {round(diet.daily_protein_g)}g | "
            f"Carbs: {round(diet.daily_carbs_g)}g | "
            f"Fats: {round(diet.daily_fats_g)}g | "
            f"Budget: ₹{round(diet.budget_per_day_inr)}/day"
        )
    else:
        lines.append("\nDIET PLAN: Not generated yet")

    # Latest recovery log
    recovery = db.query(RecoveryLog).filter(
        RecoveryLog.user_id == user.id
    ).order_by(RecoveryLog.logged_at.desc()).first()

    if recovery:
        lines.append(
            f"\nLATEST RECOVERY: Sleep {recovery.sleep_hours}h | "
            f"Soreness {recovery.soreness_level}/5 | "
            f"Energy {recovery.energy_level}/5 | "
            f"Stress {recovery.stress_level}/5"
        )

    return "\n".join(lines)


def build_system_prompt(user_context: str, language: str) -> str:
    lang_instruction = (
        "Always respond in Hindi (Devanagari script). You can use some English fitness terms."
        if language == "hi"
        else "Always respond in English."
    )

    return f"""You are FitCoach AI — a friendly, knowledgeable, and motivating personal fitness coach for Indian users.

Your personality:
- Warm, encouraging, never judgmental
- Science-backed but practical advice
- Budget-aware and culturally sensitive to Indian lifestyle
- Uses simple language, avoids complex jargon
- Gives specific, actionable advice — not vague tips
- Aware of Indian foods, gyms, home workouts, hostel life
- Never toxic or pushy with motivation

Your expertise:
- Workout programming, exercise form, muscle building
- Indian nutrition, budget meal planning, macro tracking
- Recovery, sleep, stress management
- Beginner-friendly guidance
- Injury prevention and management

Rules:
- NEVER recommend anything dangerous or medically risky
- For serious injuries or medical issues, always refer to a doctor
- Keep responses concise (under 200 words unless a detailed plan is asked)
- Use bullet points for lists, keep it scannable on mobile
- Always relate advice back to the user's specific profile and goals
- {lang_instruction}

Here is the complete profile of the user you are coaching right now:

{user_context}

Use this context to give highly personalized advice. If they ask about their workout, reference their actual plan. If they ask about food, consider their budget and vegetarian preference."""


# ── Request / Response Schemas ────────────────────────────────────────────────

class ChatMessage(BaseModel):
    message: str
    language: Optional[str] = "en"   # "en" or "hi"
    conversation_history: Optional[list] = []   # list of {role, content}


class QuickQuestion(BaseModel):
    question_type: str   # "today_workout" | "today_diet" | "recovery_tip" | "motivation"


# ── Routes ────────────────────────────────────────────────────────────────────

@router.post("/chat")
def chat_with_coach(
    request: ChatMessage,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Main conversational AI coach endpoint"""
    client       = get_groq_client()
    user_context = build_user_context(current_user, db)
    system_prompt= build_system_prompt(user_context, request.language or "en")

    # Build message history
    messages = [{"role": "system", "content": system_prompt}]

    # Add conversation history (last 6 messages to save tokens)
    for msg in (request.conversation_history or [])[-6:]:
        if msg.get("role") in ("user", "assistant") and msg.get("content"):
            messages.append({"role": msg["role"], "content": msg["content"]})

    # Add current message
    messages.append({"role": "user", "content": request.message})

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=messages,
        max_tokens=400,
        temperature=0.7,
    )

    reply = response.choices[0].message.content

    return {
        "reply":        reply,
        "user_message": request.message,
        "tokens_used":  response.usage.total_tokens,
    }


@router.post("/quick")
def quick_coach_question(
    request: QuickQuestion,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Pre-built quick questions for common daily needs"""
    client       = get_groq_client()
    user_context = build_user_context(current_user, db)
    system_prompt= build_system_prompt(user_context, "en")

    quick_prompts = {
        "today_workout": (
            "Based on my profile and current workout plan, "
            "what should I focus on in today's session? Give me 3 key tips "
            "and remind me of today's exercises with proper form cues."
        ),
        "today_diet": (
            "Based on my diet plan and fitness goal, give me practical tips "
            "for eating well today. What should I prioritize and what should I avoid?"
        ),
        "recovery_tip": (
            "Based on my latest recovery data (sleep, soreness, energy), "
            "should I train hard today or take it easy? Give me a specific recommendation."
        ),
        "motivation": (
            "I need some motivation today. Based on my fitness goal and profile, "
            "give me a short personalized pep talk that's real and not cheesy."
        ),
    }

    prompt = quick_prompts.get(request.question_type)
    if not prompt:
        raise HTTPException(
            400,
            f"Invalid question_type. Choose from: {list(quick_prompts.keys())}"
        )

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system",  "content": system_prompt},
            {"role": "user",    "content": prompt},
        ],
        max_tokens=350,
        temperature=0.75,
    )

    return {
        "question_type": request.question_type,
        "reply":         response.choices[0].message.content,
    }


@router.post("/analyze-workout")
def analyze_workout_request(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """AI analysis of the user's current workout plan with suggestions"""
    client       = get_groq_client()
    user_context = build_user_context(current_user, db)
    system_prompt= build_system_prompt(user_context, "en")

    prompt = (
        "Analyze my current workout plan in detail. Tell me: "
        "1) Is this plan well-structured for my goal? "
        "2) What are the strongest parts? "
        "3) What's missing or could be improved? "
        "4) One specific change I should make this week. "
        "Be specific and reference my actual exercises."
    )

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user",   "content": prompt},
        ],
        max_tokens=500,
        temperature=0.6,
    )

    return {"analysis": response.choices[0].message.content}


@router.post("/analyze-diet")
def analyze_diet_request(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """AI analysis of the user's diet plan"""
    client       = get_groq_client()
    user_context = build_user_context(current_user, db)
    system_prompt= build_system_prompt(user_context, "en")

    prompt = (
        "Analyze my current diet plan. Tell me: "
        "1) Am I hitting enough protein for my goal? "
        "2) Is my calorie target right? "
        "3) What Indian foods should I add more of? "
        "4) One easy budget-friendly swap I can make. "
        "Keep it practical for an Indian lifestyle."
    )

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user",   "content": prompt},
        ],
        max_tokens=400,
        temperature=0.6,
    )

    return {"analysis": response.choices[0].message.content}