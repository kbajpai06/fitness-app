from app.db.base import SessionLocal
from app.models.workout import Exercise, MuscleGroup

exercises = [
    # CHEST
    {"name": "Barbell Bench Press", "muscle_group": MuscleGroup.chest, "equipment_needed": "barbell, bench", "difficulty": "intermediate", "is_compound": True, "hypertrophy_score": 9.0, "injury_risk": 4.0, "instructions": "Lie on bench, grip bar shoulder-width, lower to chest, press up.", "substitutes": "[]"},
    {"name": "Dumbbell Bench Press", "muscle_group": MuscleGroup.chest, "equipment_needed": "dumbbells, bench", "difficulty": "beginner", "is_compound": True, "hypertrophy_score": 8.5, "injury_risk": 3.0, "instructions": "Lie on bench with dumbbells, press up and together.", "substitutes": "[]"},
    {"name": "Push Up", "muscle_group": MuscleGroup.chest, "equipment_needed": "none", "difficulty": "beginner", "is_compound": True, "hypertrophy_score": 7.0, "injury_risk": 2.0, "instructions": "Plank position, lower chest to floor, push back up.", "substitutes": "[]"},
    {"name": "Incline Dumbbell Press", "muscle_group": MuscleGroup.chest, "equipment_needed": "dumbbells, incline bench", "difficulty": "intermediate", "is_compound": True, "hypertrophy_score": 8.0, "injury_risk": 3.0, "instructions": "Set bench to 30-45 degrees, press dumbbells up.", "substitutes": "[]"},
    {"name": "Cable Fly", "muscle_group": MuscleGroup.chest, "equipment_needed": "cable machine", "difficulty": "intermediate", "is_compound": False, "hypertrophy_score": 8.5, "injury_risk": 2.5, "instructions": "Stand between cables, bring hands together in arc.", "substitutes": "[]"},

    # BACK
    {"name": "Pull Up", "muscle_group": MuscleGroup.back, "equipment_needed": "pull up bar", "difficulty": "intermediate", "is_compound": True, "hypertrophy_score": 9.0, "injury_risk": 3.0, "instructions": "Hang from bar, pull chest to bar, lower slowly.", "substitutes": "[]"},
    {"name": "Barbell Row", "muscle_group": MuscleGroup.back, "equipment_needed": "barbell", "difficulty": "intermediate", "is_compound": True, "hypertrophy_score": 9.0, "injury_risk": 4.0, "instructions": "Hinge at hips, row bar to lower chest.", "substitutes": "[]"},
    {"name": "Lat Pulldown", "muscle_group": MuscleGroup.back, "equipment_needed": "cable machine", "difficulty": "beginner", "is_compound": True, "hypertrophy_score": 8.5, "injury_risk": 2.0, "instructions": "Sit at machine, pull bar to upper chest.", "substitutes": "[]"},
    {"name": "Dumbbell Row", "muscle_group": MuscleGroup.back, "equipment_needed": "dumbbell, bench", "difficulty": "beginner", "is_compound": True, "hypertrophy_score": 8.0, "injury_risk": 2.0, "instructions": "Place knee on bench, row dumbbell to hip.", "substitutes": "[]"},
    {"name": "Deadlift", "muscle_group": MuscleGroup.back, "equipment_needed": "barbell", "difficulty": "advanced", "is_compound": True, "hypertrophy_score": 9.5, "injury_risk": 6.0, "instructions": "Stand over bar, hinge to grip, drive hips forward to stand.", "substitutes": "[]"},

    # SHOULDERS
    {"name": "Overhead Press", "muscle_group": MuscleGroup.shoulders, "equipment_needed": "barbell", "difficulty": "intermediate", "is_compound": True, "hypertrophy_score": 9.0, "injury_risk": 4.0, "instructions": "Press bar from shoulders to overhead.", "substitutes": "[]"},
    {"name": "Dumbbell Lateral Raise", "muscle_group": MuscleGroup.shoulders, "equipment_needed": "dumbbells", "difficulty": "beginner", "is_compound": False, "hypertrophy_score": 8.5, "injury_risk": 2.0, "instructions": "Raise dumbbells to sides to shoulder height.", "substitutes": "[]"},
    {"name": "Face Pull", "muscle_group": MuscleGroup.shoulders, "equipment_needed": "cable machine", "difficulty": "beginner", "is_compound": False, "hypertrophy_score": 8.0, "injury_risk": 1.5, "instructions": "Pull rope to face level, elbows high.", "substitutes": "[]"},

    # BICEPS
    {"name": "Barbell Curl", "muscle_group": MuscleGroup.biceps, "equipment_needed": "barbell", "difficulty": "beginner", "is_compound": False, "hypertrophy_score": 8.5, "injury_risk": 2.0, "instructions": "Curl bar from hips to shoulders.", "substitutes": "[]"},
    {"name": "Dumbbell Curl", "muscle_group": MuscleGroup.biceps, "equipment_needed": "dumbbells", "difficulty": "beginner", "is_compound": False, "hypertrophy_score": 8.0, "injury_risk": 1.5, "instructions": "Curl dumbbells alternating or together.", "substitutes": "[]"},
    {"name": "Hammer Curl", "muscle_group": MuscleGroup.biceps, "equipment_needed": "dumbbells", "difficulty": "beginner", "is_compound": False, "hypertrophy_score": 7.5, "injury_risk": 1.5, "instructions": "Curl with neutral grip (thumbs up).", "substitutes": "[]"},

    # TRICEPS
    {"name": "Tricep Dip", "muscle_group": MuscleGroup.triceps, "equipment_needed": "dip bars", "difficulty": "intermediate", "is_compound": True, "hypertrophy_score": 8.5, "injury_risk": 3.5, "instructions": "Lower body between bars, press back up.", "substitutes": "[]"},
    {"name": "Skull Crusher", "muscle_group": MuscleGroup.triceps, "equipment_needed": "barbell, bench", "difficulty": "intermediate", "is_compound": False, "hypertrophy_score": 8.5, "injury_risk": 3.0, "instructions": "Lower bar to forehead, extend back up.", "substitutes": "[]"},
    {"name": "Tricep Pushdown", "muscle_group": MuscleGroup.triceps, "equipment_needed": "cable machine", "difficulty": "beginner", "is_compound": False, "hypertrophy_score": 8.0, "injury_risk": 1.5, "instructions": "Push rope or bar down until arms straight.", "substitutes": "[]"},

    # LEGS
    {"name": "Barbell Squat", "muscle_group": MuscleGroup.legs, "equipment_needed": "barbell, squat rack", "difficulty": "intermediate", "is_compound": True, "hypertrophy_score": 9.5, "injury_risk": 5.0, "instructions": "Bar on traps, squat until thighs parallel, drive up.", "substitutes": "[]"},
    {"name": "Leg Press", "muscle_group": MuscleGroup.legs, "equipment_needed": "leg press machine", "difficulty": "beginner", "is_compound": True, "hypertrophy_score": 8.5, "injury_risk": 3.0, "instructions": "Push platform away, lower under control.", "substitutes": "[]"},
    {"name": "Romanian Deadlift", "muscle_group": MuscleGroup.legs, "equipment_needed": "barbell", "difficulty": "intermediate", "is_compound": True, "hypertrophy_score": 9.0, "injury_risk": 3.5, "instructions": "Hinge at hips, lower bar along legs, feel hamstring stretch.", "substitutes": "[]"},
    {"name": "Leg Curl", "muscle_group": MuscleGroup.legs, "equipment_needed": "leg curl machine", "difficulty": "beginner", "is_compound": False, "hypertrophy_score": 8.0, "injury_risk": 2.0, "instructions": "Curl legs toward glutes against resistance.", "substitutes": "[]"},
    {"name": "Bodyweight Squat", "muscle_group": MuscleGroup.legs, "equipment_needed": "none", "difficulty": "beginner", "is_compound": True, "hypertrophy_score": 6.0, "injury_risk": 1.5, "instructions": "Feet shoulder width, squat down, drive up.", "substitutes": "[]"},

    # GLUTES
    {"name": "Hip Thrust", "muscle_group": MuscleGroup.glutes, "equipment_needed": "barbell, bench", "difficulty": "intermediate", "is_compound": False, "hypertrophy_score": 9.5, "injury_risk": 2.0, "instructions": "Back on bench, bar on hips, thrust hips up.", "substitutes": "[]"},
    {"name": "Glute Bridge", "muscle_group": MuscleGroup.glutes, "equipment_needed": "none", "difficulty": "beginner", "is_compound": False, "hypertrophy_score": 7.5, "injury_risk": 1.0, "instructions": "Lie on floor, drive hips up, squeeze glutes.", "substitutes": "[]"},

    # CORE
    {"name": "Plank", "muscle_group": MuscleGroup.core, "equipment_needed": "none", "difficulty": "beginner", "is_compound": False, "hypertrophy_score": 7.0, "injury_risk": 1.0, "instructions": "Hold push up position on forearms.", "substitutes": "[]"},
    {"name": "Cable Crunch", "muscle_group": MuscleGroup.core, "equipment_needed": "cable machine", "difficulty": "beginner", "is_compound": False, "hypertrophy_score": 8.5, "injury_risk": 1.5, "instructions": "Kneel at cable, crunch torso down against resistance.", "substitutes": "[]"},
    {"name": "Hanging Leg Raise", "muscle_group": MuscleGroup.core, "equipment_needed": "pull up bar", "difficulty": "intermediate", "is_compound": False, "hypertrophy_score": 8.0, "injury_risk": 2.0, "instructions": "Hang from bar, raise legs to 90 degrees.", "substitutes": "[]"},
]

def seed():
    db = SessionLocal()
    try:
        existing = db.query(Exercise).count()
        if existing > 0:
            print(f"✅ Exercises already seeded ({existing} found), skipping.")
            return
        for ex in exercises:
            db.add(Exercise(**ex))
        db.commit()
        print(f"✅ Seeded {len(exercises)} exercises successfully!")
    finally:
        db.close()

if __name__ == "__main__":
    seed()