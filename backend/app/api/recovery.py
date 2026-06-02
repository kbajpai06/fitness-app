from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from groq import Groq
from app.db.base import get_db
from app.models.user import User
from app.models.progress import RecoveryLog
from app.api.auth import get_current_user
from app.config import settings
from datetime import date, timedelta

router = APIRouter(prefix="/recovery", tags=["Recovery"])

# ── Schemas ───────────────────────────────────────────────────────────────────

class RecoveryLogRequest(BaseModel):
    sleep_hours: Optional[float] = None       # e.g. 7.5
    sleep_quality: Optional[int] = None       # 1-5
    soreness_level: Optional[int] = None      # 1-5
    stress_level: Optional[int] = None        # 1-5
    energy_level: Optional[int] = None        # 1-5
    is_pain: Optional[bool] = False
    pain_location: Optional[str] = None       # "left knee", "lower back"
    notes: Optional[str] = None

# ── Recovery Score Calculator ─────────────────────────────────────────────────

def calculate_recovery_score(log: RecoveryLogRequest) -> int:
    """0-100 recovery score"""
    score = 100

    # Sleep scoring
    if log.sleep_hours:
        if log.sleep_hours < 5:     score -= 35
        elif log.sleep_hours < 6:   score -= 20
        elif log.sleep_hours < 7:   score -= 10
        elif log.sleep_hours >= 8:  score += 5

    # Sleep quality
    if log.sleep_quality:
        score += (log.sleep_quality - 3) * 5   # -10 to +10

    # Soreness
    if log.soreness_level:
        score -= (log.soreness_level - 1) * 8  # 0 to -32

    # Stress
    if log.stress_level:
        score -= (log.stress_level - 1) * 5    # 0 to -20

    # Energy boost
    if log.energy_level:
        score += (log.energy_level - 3) * 5    # -10 to +10

    # Pain penalty
    if log.is_pain:
        score -= 25

    return max(0, min(100, score))

def get_training_recommendation(score: int, is_pain: bool, pain_location: str) -> dict:
    """Rule-based training recommendation from recovery score"""
    if is_pain:
        return {
            "recommendation": "rest_or_rehab",
            "label": "⚠️ Rest & Rehab Day",
            "message": (
                f"You've reported pain in {pain_location or 'an area'}. "
                "Do NOT train that area today. Focus on mobility, stretching, "
                "and consider seeing a physiotherapist if it persists."
            ),
            "intensity": 0,
        }
    if score >= 80:
        return {
            "recommendation": "train_hard",
            "label": "💪 Full Training Day",
            "message": "Your recovery is excellent! Push hard today — great day for PRs.",
            "intensity": 100,
        }
    elif score >= 60:
        return {
            "recommendation": "train_normal",
            "label": "✅ Normal Training Day",
            "message": "Good recovery. Train as planned, listen to your body on last sets.",
            "intensity": 80,
        }
    elif score >= 40:
        return {
            "recommendation": "train_light",
            "label": "🟡 Light Training Day",
            "message": (
                "Moderate recovery. Consider reducing weight by 10-15%, "
                "skip failure sets, focus on form and mind-muscle connection."
            ),
            "intensity": 50,
        }
    else:
        return {
            "recommendation": "active_rest",
            "label": "😴 Active Rest Day",
            "message": (
                "Low recovery score. Take a rest day — do light walking, "
                "stretching, or yoga. Sleep early tonight."
            ),
            "intensity": 20,
        }

def get_ai_recovery_advice(log: RecoveryLogRequest, score: int, user: User) -> str:
    """Get personalized AI recovery advice using Groq"""
    if not settings.GROQ_API_KEY:
        return ""
    try:
        client = Groq(api_key=settings.GROQ_API_KEY)
        prompt = f"""
User recovery check-in:
- Sleep: {log.sleep_hours}h (quality: {log.sleep_quality}/5)
- Soreness: {log.soreness_level}/5
- Stress: {log.stress_level}/5
- Energy: {log.energy_level}/5
- Pain: {'Yes - ' + (log.pain_location or 'unspecified') if log.is_pain else 'No'}
- Recovery Score: {score}/100
- User goal: {user.fitness_goal.value if user.fitness_goal else 'general fitness'}
- Notes: {log.notes or 'None'}

Give a short (3-4 bullet points) personalized recovery advice for today.
Include: 1 mobility/stretch suggestion, 1 nutrition tip, 1 sleep tip if relevant.
Be specific and practical for an Indian user.
"""
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": "You are a fitness recovery specialist. Give concise, practical advice."},
                {"role": "user",   "content": prompt},
            ],
            max_tokens=250,
            temperature=0.6,
        )
        return response.choices[0].message.content
    except Exception:
        return ""

# ── Routes ────────────────────────────────────────────────────────────────────

@router.post("/log")
def log_recovery(
    data: RecoveryLogRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Log today's recovery check-in and get AI recommendation"""
    score          = calculate_recovery_score(data)
    training_rec   = get_training_recommendation(score, data.is_pain or False, data.pain_location)
    ai_advice      = get_ai_recovery_advice(data, score, current_user)

    log = RecoveryLog(
        user_id           = current_user.id,
        sleep_hours       = data.sleep_hours,
        sleep_quality     = data.sleep_quality,
        soreness_level    = data.soreness_level,
        stress_level      = data.stress_level,
        energy_level      = data.energy_level,
        is_pain           = data.is_pain or False,
        pain_location     = data.pain_location,
        notes             = data.notes,
        ai_recommendation = ai_advice,
    )
    db.add(log)
    db.commit()
    db.refresh(log)

    return {
        "log_id":              log.id,
        "recovery_score":      score,
        "training_recommendation": training_rec,
        "ai_advice":           ai_advice,
        "logged_at":           log.logged_at,
    }


@router.get("/history")
def get_recovery_history(
    days: int = 7,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get last N days of recovery logs"""
    since = date.today() - timedelta(days=days)
    logs = (
        db.query(RecoveryLog)
        .filter(
            RecoveryLog.user_id == current_user.id,
            RecoveryLog.logged_at >= since,
        )
        .order_by(RecoveryLog.logged_at.desc())
        .all()
    )

    return {
        "days_requested": days,
        "total_logs": len(logs),
        "logs": [
            {
                "id":             l.id,
                "sleep_hours":    l.sleep_hours,
                "sleep_quality":  l.sleep_quality,
                "soreness_level": l.soreness_level,
                "stress_level":   l.stress_level,
                "energy_level":   l.energy_level,
                "is_pain":        l.is_pain,
                "recovery_score": calculate_recovery_score(RecoveryLogRequest(
                    sleep_hours=l.sleep_hours,
                    sleep_quality=l.sleep_quality,
                    soreness_level=l.soreness_level,
                    stress_level=l.stress_level,
                    energy_level=l.energy_level,
                    is_pain=l.is_pain,
                )),
                "ai_recommendation": l.ai_recommendation,
                "logged_at":      l.logged_at,
            }
            for l in logs
        ],
    }


@router.get("/today")
def get_today_recovery(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Check if user has logged recovery today"""
    today_start = date.today()
    log = (
        db.query(RecoveryLog)
        .filter(
            RecoveryLog.user_id == current_user.id,
            RecoveryLog.logged_at >= today_start,
        )
        .order_by(RecoveryLog.logged_at.desc())
        .first()
    )

    if not log:
        return {"logged_today": False, "message": "No recovery check-in yet today."}

    score = calculate_recovery_score(RecoveryLogRequest(
        sleep_hours=log.sleep_hours,
        sleep_quality=log.sleep_quality,
        soreness_level=log.soreness_level,
        stress_level=log.stress_level,
        energy_level=log.energy_level,
        is_pain=log.is_pain,
    ))

    return {
        "logged_today":    True,
        "recovery_score":  score,
        "training_recommendation": get_training_recommendation(
            score, log.is_pain, log.pain_location
        ),
        "ai_advice":       log.ai_recommendation,
        "logged_at":       log.logged_at,
    }