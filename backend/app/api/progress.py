from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import date, timedelta
from app.db.base import get_db
from app.models.user import User
from app.models.progress import ProgressLog
from app.api.auth import get_current_user

router = APIRouter(prefix="/progress", tags=["Progress"])

# ── Schemas ───────────────────────────────────────────────────────────────────

class ProgressLogRequest(BaseModel):
    weight_kg:     Optional[float] = None
    body_fat_pct:  Optional[float] = None
    chest_cm:      Optional[float] = None
    waist_cm:      Optional[float] = None
    hips_cm:       Optional[float] = None
    arms_cm:       Optional[float] = None
    notes:         Optional[str]   = None

# ── Routes ────────────────────────────────────────────────────────────────────

@router.post("/log")
def log_progress(
    data: ProgressLogRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Log body measurements and weight"""
    log = ProgressLog(
        user_id      = current_user.id,
        weight_kg    = data.weight_kg,
        body_fat_pct = data.body_fat_pct,
        chest_cm     = data.chest_cm,
        waist_cm     = data.waist_cm,
        hips_cm      = data.hips_cm,
        arms_cm      = data.arms_cm,
        notes        = data.notes,
    )
    db.add(log)

    # Update user's current weight if provided
    if data.weight_kg:
        current_user.weight_kg = data.weight_kg

    db.commit()
    db.refresh(log)

    return {"message": "Progress logged!", "log_id": log.id, "logged_at": log.logged_at}


@router.get("/history")
def get_progress_history(
    days: int = 30,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get progress history with trend analysis"""
    since = date.today() - timedelta(days=days)
    logs = (
        db.query(ProgressLog)
        .filter(
            ProgressLog.user_id  == current_user.id,
            ProgressLog.logged_at >= since,
        )
        .order_by(ProgressLog.logged_at.asc())
        .all()
    )

    if not logs:
        return {"total_logs": 0, "logs": [], "trends": None}

    # Calculate trends
    first = logs[0]
    last  = logs[-1]

    trends = {}
    if first.weight_kg and last.weight_kg:
        diff = round(last.weight_kg - first.weight_kg, 1)
        trends["weight_change_kg"] = diff
        trends["weight_trend"]     = "📉 Losing" if diff < 0 else "📈 Gaining" if diff > 0 else "➡️ Maintaining"

    if first.waist_cm and last.waist_cm:
        trends["waist_change_cm"] = round(last.waist_cm - first.waist_cm, 1)

    if first.arms_cm and last.arms_cm:
        trends["arms_change_cm"]  = round(last.arms_cm - first.arms_cm, 1)

    return {
        "days_requested": days,
        "total_logs": len(logs),
        "trends": trends,
        "logs": [
            {
                "id":           l.id,
                "weight_kg":    l.weight_kg,
                "body_fat_pct": l.body_fat_pct,
                "chest_cm":     l.chest_cm,
                "waist_cm":     l.waist_cm,
                "hips_cm":      l.hips_cm,
                "arms_cm":      l.arms_cm,
                "notes":        l.notes,
                "logged_at":    l.logged_at,
            }
            for l in logs
        ],
    }


@router.get("/summary")
def get_progress_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get overall progress summary — first vs latest log"""
    logs = (
        db.query(ProgressLog)
        .filter(ProgressLog.user_id == current_user.id)
        .order_by(ProgressLog.logged_at.asc())
        .all()
    )

    if not logs:
        return {"message": "No progress logs yet. Start logging!"}

    first = logs[0]
    last  = logs[-1]
    days_tracked = (last.logged_at.date() - first.logged_at.date()).days + 1

    def delta(a, b):
        if a and b:
            return round(b - a, 1)
        return None

    return {
        "days_tracked":    days_tracked,
        "total_logs":      len(logs),
        "start_date":      first.logged_at.date(),
        "latest_date":     last.logged_at.date(),
        "current": {
            "weight_kg":    last.weight_kg,
            "body_fat_pct": last.body_fat_pct,
            "chest_cm":     last.chest_cm,
            "waist_cm":     last.waist_cm,
            "arms_cm":      last.arms_cm,
        },
        "changes": {
            "weight_kg":    delta(first.weight_kg,    last.weight_kg),
            "body_fat_pct": delta(first.body_fat_pct, last.body_fat_pct),
            "chest_cm":     delta(first.chest_cm,     last.chest_cm),
            "waist_cm":     delta(first.waist_cm,     last.waist_cm),
            "arms_cm":      delta(first.arms_cm,      last.arms_cm),
        },
        "goal":            current_user.fitness_goal,
        "target_weight":   current_user.target_weight_kg,
    }