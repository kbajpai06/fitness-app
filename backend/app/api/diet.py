from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import date
from app.db.base import get_db
from app.models.user import User
from app.models.diet import FoodItem, DietPlan, Meal, MealItem
from app.api.auth import get_current_user

router = APIRouter(prefix="/diet", tags=["Diet Planner"])

# ── Macro Calculators ─────────────────────────────────────────────────────────

def calculate_bmr(weight_kg, height_cm, age, gender):
    if gender == "female":
        return 10 * weight_kg + 6.25 * height_cm - 5 * age - 161
    return 10 * weight_kg + 6.25 * height_cm - 5 * age + 5

def calculate_tdee(bmr, days_per_week):
    if days_per_week <= 1:   return bmr * 1.2
    if days_per_week <= 3:   return bmr * 1.375
    if days_per_week <= 5:   return bmr * 1.55
    return bmr * 1.725

def calculate_targets(user):
    w, h, a = user.weight_kg or 70, user.height_cm or 170, user.age or 25
    gender   = user.gender or "male"
    days     = user.days_per_week or 3
    goal     = user.fitness_goal.value if user.fitness_goal else "general_fitness"

    tdee = calculate_tdee(calculate_bmr(w, h, a, gender), days)

    if goal == "weight_loss":    calories = tdee - 400
    elif goal == "muscle_gain":  calories = tdee + 300
    else:                        calories = tdee

    if goal == "muscle_gain":
        protein_g, fats_g = w * 2.0, w * 0.9
    elif goal == "weight_loss":
        protein_g, fats_g = w * 2.2, w * 0.8
    else:
        protein_g, fats_g = w * 1.6, w * 1.0

    carbs_g = (calories - protein_g * 4 - fats_g * 9) / 4
    return {
        "calories":  round(calories),
        "protein_g": round(protein_g),
        "carbs_g":   round(max(carbs_g, 50)),
        "fats_g":    round(fats_g),
    }

# ── Named Meal Templates ──────────────────────────────────────────────────────
# Each meal is a REAL dish with REALISTIC fixed portion sizes.
# Portions are for a 70kg person. We scale them to user's calorie target.
# Format: { "food_name": grams }

# pref: "veg" | "egg" | "nonveg" | "all"

BREAKFAST_MEALS = [
    {
        "name": "Masala Oats with Boiled Egg",
        "style": "modern",
        "pref": "egg",
        "base_calories": 420,
        "base_protein": 24,
        "items": [
            {"food_name": "Rolled Oats",         "qty_g": 80,  "note": "cooked with veggies & spices"},
            {"food_name": "Boiled Eggs",          "qty_g": 110, "note": "2 whole eggs"},
            {"food_name": "Milk (Full Fat)",      "qty_g": 100, "note": "1 small glass"},
        ]
    },
    {
        "name": "Poha with Peanuts & Curd",
        "style": "classic",
        "pref": "veg",
        "base_calories": 380,
        "base_protein": 14,
        "items": [
            {"food_name": "Poha (Flattened Rice)", "qty_g": 100, "note": "cooked with mustard, onion, peas"},
            {"food_name": "Peanuts (Roasted)",     "qty_g": 20,  "note": "for crunch & protein"},
            {"food_name": "Curd (Dahi)",           "qty_g": 100, "note": "1 small bowl"},
        ]
    },
    {
        "name": "Moong Dal Chilla with Green Chutney",
        "style": "classic",
        "pref": "veg",
        "base_calories": 350,
        "base_protein": 22,
        "items": [
            {"food_name": "Besan (Chickpea Flour)", "qty_g": 80,  "note": "2 chillas on tawa"},
            {"food_name": "Curd (Dahi)",            "qty_g": 100, "note": "side bowl"},
            {"food_name": "Banana",                 "qty_g": 100, "note": "1 medium banana"},
        ]
    },
    {
        "name": "Egg Bhurji with Brown Bread",
        "style": "modern",
        "pref": "egg",
        "base_calories": 430,
        "base_protein": 28,
        "items": [
            {"food_name": "Egg Bhurji (2 eggs)",  "qty_g": 150, "note": "spiced scrambled eggs"},
            {"food_name": "Whole Wheat Bread",    "qty_g": 80,  "note": "2 slices toasted"},
            {"food_name": "Milk (Full Fat)",      "qty_g": 150, "note": "1 glass"},
        ]
    },
    {
        "name": "Oats Smoothie Bowl with Banana",
        "style": "modern",
        "pref": "veg",
        "base_calories": 400,
        "base_protein": 18,
        "items": [
            {"food_name": "Rolled Oats",     "qty_g": 60,  "note": "blended or soaked overnight"},
            {"food_name": "Greek Yogurt",    "qty_g": 150, "note": "base of bowl"},
            {"food_name": "Banana",          "qty_g": 100, "note": "sliced on top"},
            {"food_name": "Almonds",         "qty_g": 15,  "note": "crushed topping"},
        ]
    },
    {
        "name": "Vegetable Upma with Sambar",
        "style": "south",
        "pref": "veg",
        "base_calories": 360,
        "base_protein": 12,
        "items": [
            {"food_name": "Semolina (Suji/Rava)", "qty_g": 100, "note": "upma with veggies"},
            {"food_name": "Sambar",               "qty_g": 150, "note": "1 small bowl"},
            {"food_name": "Curd (Dahi)",          "qty_g": 100, "note": "side"},
        ]
    },
    {
        "name": "Paneer Bhurji with Multigrain Bread",
        "style": "modern",
        "pref": "veg",
        "base_calories": 460,
        "base_protein": 26,
        "items": [
            {"food_name": "Paneer",              "qty_g": 100, "note": "crumbled & spiced"},
            {"food_name": "Whole Wheat Bread",   "qty_g": 80,  "note": "2 slices"},
            {"food_name": "Milk (Full Fat)",     "qty_g": 150, "note": "1 glass"},
        ]
    },
    {
        "name": "Dalia Khichdi with Curd",
        "style": "classic",
        "pref": "veg",
        "base_calories": 370,
        "base_protein": 14,
        "items": [
            {"food_name": "Dalia (Broken Wheat)", "qty_g": 100, "note": "cooked with moong dal"},
            {"food_name": "Moong Dal",            "qty_g": 30,  "note": "mixed in dalia"},
            {"food_name": "Curd (Dahi)",          "qty_g": 150, "note": "side bowl"},
        ]
    },
    {
        "name": "Chicken Sandwich with Milk",
        "style": "modern",
        "pref": "nonveg",
        "base_calories": 480,
        "base_protein": 38,
        "items": [
            {"food_name": "Chicken Breast (Cooked)", "qty_g": 100, "note": "grilled, shredded"},
            {"food_name": "Whole Wheat Bread",       "qty_g": 80,  "note": "2 slices"},
            {"food_name": "Milk (Full Fat)",         "qty_g": 200, "note": "1 glass"},
        ]
    },
    {
        "name": "Sprouted Moong Chaat with Curd",
        "style": "classic",
        "pref": "veg",
        "base_calories": 300,
        "base_protein": 18,
        "items": [
            {"food_name": "Sprouts (Mixed)",  "qty_g": 150, "note": "with onion, tomato, lemon"},
            {"food_name": "Greek Yogurt",     "qty_g": 150, "note": "side bowl"},
            {"food_name": "Apple",            "qty_g": 150, "note": "1 medium apple"},
        ]
    },
]

LUNCH_MEALS = [
    {
        "name": "Dal Chawal with Mixed Sabzi",
        "style": "classic",
        "pref": "veg",
        "base_calories": 650,
        "base_protein": 26,
        "items": [
            {"food_name": "Toor Dal",              "qty_g": 80,  "note": "1 katori cooked dal"},
            {"food_name": "White Rice (Cooked)",   "qty_g": 200, "note": "1.5 katori cooked rice"},
            {"food_name": "Mixed Sabzi",           "qty_g": 150, "note": "seasonal veggies"},
            {"food_name": "Curd (Dahi)",           "qty_g": 100, "note": "side"},
        ]
    },
    {
        "name": "Rajma Chawal",
        "style": "north",
        "pref": "veg",
        "base_calories": 600,
        "base_protein": 24,
        "items": [
            {"food_name": "Rajma (Kidney Beans)",  "qty_g": 150, "note": "cooked in tomato gravy"},
            {"food_name": "White Rice (Cooked)",   "qty_g": 200, "note": "steamed rice"},
            {"food_name": "Curd (Dahi)",           "qty_g": 100, "note": "raita"},
        ]
    },
    {
        "name": "Chicken Roti Bowl",
        "style": "modern",
        "pref": "nonveg",
        "base_calories": 680,
        "base_protein": 48,
        "items": [
            {"food_name": "Chicken Breast (Cooked)", "qty_g": 150, "note": "grilled/curry"},
            {"food_name": "Whole Wheat Roti",        "qty_g": 120, "note": "2 medium rotis"},
            {"food_name": "Mixed Sabzi",             "qty_g": 100, "note": "greens"},
            {"food_name": "Curd (Dahi)",             "qty_g": 100, "note": "side"},
        ]
    },
    {
        "name": "Palak Paneer with Roti",
        "style": "north",
        "pref": "veg",
        "base_calories": 620,
        "base_protein": 28,
        "items": [
            {"food_name": "Paneer",              "qty_g": 100, "note": "in spinach gravy"},
            {"food_name": "Spinach (Palak)",     "qty_g": 100, "note": "gravy base"},
            {"food_name": "Whole Wheat Roti",    "qty_g": 120, "note": "2 rotis"},
            {"food_name": "Curd (Dahi)",         "qty_g": 100, "note": "side"},
        ]
    },
    {
        "name": "Soya Chunks Curry with Rice",
        "style": "classic",
        "pref": "veg",
        "base_calories": 580,
        "base_protein": 40,
        "items": [
            {"food_name": "Soya Chunks",           "qty_g": 80,  "note": "cooked in masala"},
            {"food_name": "White Rice (Cooked)",   "qty_g": 200, "note": "steamed"},
            {"food_name": "Mixed Sabzi",           "qty_g": 100, "note": "side"},
        ]
    },
    {
        "name": "Egg Curry with Brown Rice",
        "style": "classic",
        "pref": "egg",
        "base_calories": 620,
        "base_protein": 30,
        "items": [
            {"food_name": "Whole Egg",             "qty_g": 150, "note": "3 eggs in curry"},
            {"food_name": "Brown Rice (Cooked)",   "qty_g": 200, "note": "steamed"},
            {"food_name": "Mixed Sabzi",           "qty_g": 100, "note": "side sabzi"},
        ]
    },
    {
        "name": "Chana Masala with Bhatura/Roti",
        "style": "north",
        "pref": "veg",
        "base_calories": 640,
        "base_protein": 22,
        "items": [
            {"food_name": "Kabuli Chana",          "qty_g": 150, "note": "spiced chana masala"},
            {"food_name": "Whole Wheat Roti",      "qty_g": 120, "note": "2 rotis"},
            {"food_name": "Curd (Dahi)",           "qty_g": 100, "note": "lassi/raita"},
        ]
    },
]

DINNER_MEALS = [
    {
        "name": "Dal Tadka with 2 Roti & Sabzi",
        "style": "classic",
        "pref": "veg",
        "base_calories": 520,
        "base_protein": 22,
        "items": [
            {"food_name": "Masoor Dal",          "qty_g": 80,  "note": "tempered with ghee"},
            {"food_name": "Whole Wheat Roti",    "qty_g": 120, "note": "2 rotis"},
            {"food_name": "Mixed Sabzi",         "qty_g": 150, "note": "seasonal"},
        ]
    },
    {
        "name": "Grilled Chicken with Sweet Potato & Broccoli",
        "style": "modern",
        "pref": "nonveg",
        "base_calories": 500,
        "base_protein": 45,
        "items": [
            {"food_name": "Chicken Breast (Cooked)", "qty_g": 150, "note": "grilled with spices"},
            {"food_name": "Sweet Potato (Boiled)",   "qty_g": 150, "note": "baked/boiled"},
            {"food_name": "Broccoli",                "qty_g": 100, "note": "steamed"},
        ]
    },
    {
        "name": "Moong Dal Khichdi with Curd",
        "style": "classic",
        "pref": "veg",
        "base_calories": 490,
        "base_protein": 20,
        "items": [
            {"food_name": "Moong Dal",             "qty_g": 80,  "note": "khichdi style"},
            {"food_name": "White Rice (Cooked)",   "qty_g": 150, "note": "mixed in khichdi"},
            {"food_name": "Curd (Dahi)",           "qty_g": 150, "note": "cooling side"},
        ]
    },
    {
        "name": "Paneer Tikka with Roti & Salad",
        "style": "north",
        "pref": "veg",
        "base_calories": 560,
        "base_protein": 30,
        "items": [
            {"food_name": "Paneer",              "qty_g": 120, "note": "marinated & grilled"},
            {"food_name": "Whole Wheat Roti",    "qty_g": 120, "note": "2 rotis"},
            {"food_name": "Spinach (Palak)",     "qty_g": 80,  "note": "salad/side"},
        ]
    },
    {
        "name": "Egg Bhurji Roti Wrap",
        "style": "modern",
        "pref": "egg",
        "base_calories": 510,
        "base_protein": 32,
        "items": [
            {"food_name": "Egg Bhurji (2 eggs)", "qty_g": 150, "note": "wrapped in roti"},
            {"food_name": "Whole Wheat Roti",    "qty_g": 120, "note": "2 rotis as wrap"},
            {"food_name": "Curd (Dahi)",         "qty_g": 100, "note": "side dip"},
        ]
    },
    {
        "name": "Soya Keema with Roti",
        "style": "classic",
        "pref": "veg",
        "base_calories": 530,
        "base_protein": 38,
        "items": [
            {"food_name": "Soya Chunks",         "qty_g": 80,  "note": "minced, keema style"},
            {"food_name": "Whole Wheat Roti",    "qty_g": 120, "note": "2-3 rotis"},
            {"food_name": "Mixed Sabzi",         "qty_g": 100, "note": "salad/side"},
        ]
    },
    {
        "name": "Idli Sambar (South Special)",
        "style": "south",
        "pref": "veg",
        "base_calories": 400,
        "base_protein": 14,
        "items": [
            {"food_name": "Rice (Idli/Dosa)",  "qty_g": 200, "note": "4 medium idlis"},
            {"food_name": "Sambar",            "qty_g": 200, "note": "2 bowls"},
            {"food_name": "Curd (Dahi)",       "qty_g": 100, "note": "side"},
        ]
    },
]

SNACK_MEALS = [
    {
        "name": "Peanut Butter Banana Toast",
        "style": "modern",
        "pref": "veg",
        "base_calories": 320,
        "base_protein": 12,
        "items": [
            {"food_name": "Whole Wheat Bread",  "qty_g": 60,  "note": "2 slices"},
            {"food_name": "Peanut Butter",      "qty_g": 30,  "note": "spread"},
            {"food_name": "Banana",             "qty_g": 100, "note": "sliced on top"},
        ]
    },
    {
        "name": "Roasted Makhana & Almonds",
        "style": "classic",
        "pref": "veg",
        "base_calories": 220,
        "base_protein": 8,
        "items": [
            {"food_name": "Makhana (Fox Nuts)", "qty_g": 30,  "note": "roasted with spices"},
            {"food_name": "Almonds",            "qty_g": 20,  "note": "handful"},
            {"food_name": "Apple",              "qty_g": 150, "note": "1 apple"},
        ]
    },
    {
        "name": "Chana Chaat",
        "style": "classic",
        "pref": "veg",
        "base_calories": 250,
        "base_protein": 12,
        "items": [
            {"food_name": "Chana Chaat",        "qty_g": 150, "note": "spiced, tangy"},
            {"food_name": "Greek Yogurt",       "qty_g": 100, "note": "protein boost"},
        ]
    },
    {
        "name": "Protein Shake with Banana",
        "style": "modern",
        "pref": "all",
        "base_calories": 300,
        "base_protein": 28,
        "items": [
            {"food_name": "Whey Protein",       "qty_g": 30,  "note": "1 scoop in milk/water"},
            {"food_name": "Milk (Full Fat)",    "qty_g": 250, "note": "shake base"},
            {"food_name": "Banana",             "qty_g": 100, "note": "blended in"},
        ]
    },
    {
        "name": "Sprouted Moong with Lemon",
        "style": "classic",
        "pref": "veg",
        "base_calories": 180,
        "base_protein": 12,
        "items": [
            {"food_name": "Sprouts (Mixed)",    "qty_g": 150, "note": "with lemon, chaat masala"},
            {"food_name": "Peanuts (Roasted)",  "qty_g": 20,  "note": "mixed in"},
        ]
    },
    {
        "name": "Curd & Fruit Bowl",
        "style": "modern",
        "pref": "veg",
        "base_calories": 200,
        "base_protein": 10,
        "items": [
            {"food_name": "Greek Yogurt",  "qty_g": 150, "note": "base"},
            {"food_name": "Banana",        "qty_g": 100, "note": "sliced"},
            {"food_name": "Apple",         "qty_g": 100, "note": "diced"},
        ]
    },
    {
        "name": "Boiled Eggs & Peanuts",
        "style": "modern",
        "pref": "egg",
        "base_calories": 280,
        "base_protein": 20,
        "items": [
            {"food_name": "Boiled Eggs",        "qty_g": 110, "note": "2 eggs with salt/pepper"},
            {"food_name": "Peanuts (Roasted)",  "qty_g": 30,  "note": "handful"},
        ]
    },
]

# ── 7-Day Rotation ────────────────────────────────────────────────────────────
# Each day picks indices from the meal lists above.
# We rotate across breakfast/snack choices; lunch/dinner vary by day.

DAY_ROTATION = {
    #        breakfast_idx  lunch_idx  dinner_idx  snack_idx
    1:  {"b": 0, "l": 0, "d": 0, "s": 0},
    2:  {"b": 1, "l": 1, "d": 1, "s": 1},
    3:  {"b": 2, "l": 2, "d": 2, "s": 2},
    4:  {"b": 3, "l": 3, "d": 3, "s": 3},
    5:  {"b": 4, "l": 4, "d": 4, "s": 4},
    6:  {"b": 5, "l": 5, "d": 5, "s": 5},
    7:  {"b": 6, "l": 6, "d": 6, "s": 6},
}

def filter_meal(meal: dict, is_vegetarian: bool, is_eggetarian: bool) -> bool:
    """Return True if this meal is allowed for the user's preference"""
    pref = meal["pref"]
    if pref == "all":
        return True
    if pref == "veg":
        return True
    if pref == "egg" and (is_eggetarian or not is_vegetarian):
        return True
    if pref == "nonveg" and not is_vegetarian:
        return True
    return False

def get_allowed_meals(meal_list, is_vegetarian, is_eggetarian):
    return [m for m in meal_list if filter_meal(m, is_vegetarian, is_eggetarian)]

def scale_meal(meal: dict, target_calories: float) -> dict:
    """Scale all quantities proportionally to hit target calories"""
    if meal["base_calories"] <= 0:
        return meal
    scale = target_calories / meal["base_calories"]
    # Cap scaling between 0.7x and 1.5x to stay realistic
    scale = max(0.7, min(scale, 1.5))
    scaled_items = []
    for item in meal["items"]:
        scaled_items.append({**item, "qty_g": round(item["qty_g"] * scale)})
    return {**meal, "items": scaled_items,
            "scaled_calories": round(meal["base_calories"] * scale),
            "scaled_protein":  round(meal["base_protein"]  * scale, 1)}

def resolve_food_items(db: Session, meal: dict) -> list:
    """Convert food names to DB records and calculate per-item macros"""
    resolved = []
    for item in meal["items"]:
        food = db.query(FoodItem).filter(
            FoodItem.name.ilike(f"%{item['food_name'].split('(')[0].strip()}%")
        ).first()
        if not food:
            continue
        qty = item["qty_g"]
        resolved.append({
            "food_id":         food.id,
            "food_name":       food.name,
            "food_name_hindi": food.name_hindi,
            "quantity_g":      qty,
            "note":            item.get("note", ""),
            "calories":        round((food.calories_per_100g * qty) / 100),
            "protein_g":       round((food.protein_per_100g  * qty) / 100, 1),
            "carbs_g":         round((food.carbs_per_100g    * qty) / 100, 1),
            "fats_g":          round((food.fats_per_100g     * qty) / 100, 1),
            "cost_inr":        round((food.avg_price_per_100g_inr * qty) / 100, 1),
        })
    return resolved

# ── Calorie split per meal ────────────────────────────────────────────────────
MEAL_SPLIT = {"breakfast": 0.28, "lunch": 0.35, "dinner": 0.28, "snack": 0.09}

# ── Routes ────────────────────────────────────────────────────────────────────

@router.get("/targets")
def get_macro_targets(current_user: User = Depends(get_current_user)):
    if not current_user.weight_kg or not current_user.height_cm:
        raise HTTPException(400, "Please update weight and height in profile first.")
    return {
        "daily_targets": calculate_targets(current_user),
        "goal": current_user.fitness_goal,
    }


@router.post("/generate")
def generate_diet_plan(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not current_user.weight_kg or not current_user.height_cm:
        raise HTTPException(400, "Please update weight and height in profile first.")

    targets     = calculate_targets(current_user)
    budget      = (current_user.monthly_food_budget / 30) if current_user.monthly_food_budget else 150.0
    is_veg      = current_user.is_vegetarian or False
    is_egg      = not is_veg   # treat non-veg as eggetarian too

    # Deactivate old plans
    db.query(DietPlan).filter(
        DietPlan.user_id == current_user.id,
        DietPlan.is_active == True
    ).update({"is_active": False})

    plan = DietPlan(
        user_id=current_user.id,
        daily_calories=targets["calories"],
        daily_protein_g=targets["protein_g"],
        daily_carbs_g=targets["carbs_g"],
        daily_fats_g=targets["fats_g"],
        budget_per_day_inr=budget,
        is_active=True,
        ai_generated=True,
    )
    db.add(plan)
    db.flush()

    all_days = []

    breakfast_pool = get_allowed_meals(BREAKFAST_MEALS, is_veg, is_egg)
    lunch_pool     = get_allowed_meals(LUNCH_MEALS,     is_veg, is_egg)
    dinner_pool    = get_allowed_meals(DINNER_MEALS,    is_veg, is_egg)
    snack_pool     = get_allowed_meals(SNACK_MEALS,     is_veg, is_egg)

    for day_num in range(1, 8):
        rot = DAY_ROTATION[day_num]

        day_meals = [
            ("breakfast", breakfast_pool[rot["b"] % len(breakfast_pool)], MEAL_SPLIT["breakfast"]),
            ("lunch",     lunch_pool    [rot["l"] % len(lunch_pool)],     MEAL_SPLIT["lunch"]),
            ("dinner",    dinner_pool   [rot["d"] % len(dinner_pool)],    MEAL_SPLIT["dinner"]),
            ("snack",     snack_pool    [rot["s"] % len(snack_pool)],     MEAL_SPLIT["snack"]),
        ]

        day_data  = {"day": day_num, "meals": []}
        day_cost  = 0.0

        for meal_type, template, cal_pct in day_meals:
            target_cal    = targets["calories"] * cal_pct
            scaled        = scale_meal(template, target_cal)
            resolved_items= resolve_food_items(db, scaled)

            total_cal     = sum(i["calories"] for i in resolved_items)
            total_protein = sum(i["protein_g"] for i in resolved_items)
            total_cost    = sum(i["cost_inr"]  for i in resolved_items)
            day_cost     += total_cost

            meal = Meal(
                diet_plan_id=plan.id,
                meal_type=meal_type,
                day_of_week=day_num,
                total_calories=total_cal,
                total_protein_g=total_protein,
                notes=template["name"],
            )
            db.add(meal)
            db.flush()

            for item in resolved_items:
                db.add(MealItem(
                    meal_id=meal.id,
                    food_item_id=item["food_id"],
                    quantity_g=item["quantity_g"],
                ))

            day_data["meals"].append({
                "meal_type":          meal_type,
                "dish_name":          template["name"],
                "style":              template["style"],
                "total_calories":     total_cal,
                "total_protein_g":    total_protein,
                "estimated_cost_inr": round(total_cost, 1),
                "items":              resolved_items,
            })

        day_data["total_day_cost_inr"] = round(day_cost, 1)
        all_days.append(day_data)

    db.commit()

    return {
        "message":            "7-day realistic Indian diet plan generated! 🍛",
        "plan_id":            plan.id,
        "daily_targets":      targets,
        "budget_per_day_inr": budget,
        "is_vegetarian":      is_veg,
        "days":               all_days,
    }


@router.get("/today")
def get_todays_plan(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    plan = db.query(DietPlan).filter(
        DietPlan.user_id == current_user.id,
        DietPlan.is_active == True,
    ).first()
    if not plan:
        raise HTTPException(404, "No active diet plan. Call POST /diet/generate first.")

    days_since = (date.today() - plan.created_at.date()).days
    day_number  = (days_since % 7) + 1

    return _get_day_response(plan, day_number, db, today=True)


@router.get("/day/{day_number}")
def get_specific_day(
    day_number: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not 1 <= day_number <= 7:
        raise HTTPException(400, "Day number must be 1–7.")
    plan = db.query(DietPlan).filter(
        DietPlan.user_id == current_user.id,
        DietPlan.is_active == True,
    ).first()
    if not plan:
        raise HTTPException(404, "No active diet plan found.")
    return _get_day_response(plan, day_number, db)


def _get_day_response(plan, day_number, db, today=False):
    meals_db = db.query(Meal).filter(
        Meal.diet_plan_id == plan.id,
        Meal.day_of_week  == day_number,
    ).all()

    result_meals = []
    total_cost   = 0.0

    for meal in meals_db:
        items = []
        for mi in meal.items:
            food = db.query(FoodItem).filter(FoodItem.id == mi.food_item_id).first()
            cost = round((food.avg_price_per_100g_inr * mi.quantity_g) / 100, 1)
            total_cost += cost
            items.append({
                "food_name":       food.name,
                "food_name_hindi": food.name_hindi,
                "quantity_g":      mi.quantity_g,
                "calories":        round((food.calories_per_100g * mi.quantity_g) / 100),
                "protein_g":       round((food.protein_per_100g  * mi.quantity_g) / 100, 1),
                "cost_inr":        cost,
            })
        result_meals.append({
            "meal_type":       meal.meal_type,
            "dish_name":       meal.notes,
            "total_calories":  meal.total_calories,
            "total_protein_g": meal.total_protein_g,
            "items":           items,
        })

    response = {
        "day": day_number,
        "daily_targets": {
            "calories":  plan.daily_calories,
            "protein_g": plan.daily_protein_g,
        },
        "estimated_cost_inr": round(total_cost, 1),
        "meals": result_meals,
    }
    if today:
        response["today"]      = date.today().isoformat()
        response["cycle_day"]  = day_number

    return response


@router.get("/foods/search")
def search_foods(
    query: str,
    vegetarian_only: bool = False,
    db: Session = Depends(get_db),
):
    foods = db.query(FoodItem).filter(FoodItem.name.ilike(f"%{query}%"))
    if vegetarian_only:
        foods = foods.filter(FoodItem.is_vegetarian == True)
    return [
        {
            "id": f.id, "name": f.name, "name_hindi": f.name_hindi,
            "calories_per_100g": f.calories_per_100g,
            "protein_per_100g":  f.protein_per_100g,
            "price_per_100g_inr":f.avg_price_per_100g_inr,
            "is_vegetarian":     f.is_vegetarian,
        }
        for f in foods.limit(10).all()
    ]