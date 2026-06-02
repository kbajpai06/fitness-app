from app.db.base import SessionLocal
from app.models.diet import FoodItem

foods = [
    # ═══════════════════════════════════════════
    # BREAKFAST INGREDIENTS
    # ═══════════════════════════════════════════

    # Grains / Base
    {"name": "Rolled Oats", "name_hindi": "ओट्स", "category": "breakfast_grain", "region": "all", "calories_per_100g": 389, "protein_per_100g": 17.0, "carbs_per_100g": 66.0, "fats_per_100g": 7.0, "fiber_per_100g": 10.6, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.8, "is_hostel_friendly": True},
    {"name": "Poha (Flattened Rice)", "name_hindi": "पोहा", "category": "breakfast_grain", "region": "all", "calories_per_100g": 333, "protein_per_100g": 6.0, "carbs_per_100g": 76.0, "fats_per_100g": 0.5, "fiber_per_100g": 2.0, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.6, "is_hostel_friendly": True},
    {"name": "Semolina (Suji/Rava)", "name_hindi": "सूजी", "category": "breakfast_grain", "region": "all", "calories_per_100g": 360, "protein_per_100g": 13.0, "carbs_per_100g": 73.0, "fats_per_100g": 1.0, "fiber_per_100g": 3.9, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.5, "is_hostel_friendly": True},
    {"name": "Whole Wheat Bread", "name_hindi": "ब्राउन ब्रेड", "category": "breakfast_grain", "region": "all", "calories_per_100g": 247, "protein_per_100g": 9.0, "carbs_per_100g": 47.0, "fats_per_100g": 3.0, "fiber_per_100g": 4.0, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.5, "is_hostel_friendly": True},
    {"name": "Besan (Chickpea Flour)", "name_hindi": "बेसन", "category": "breakfast_grain", "region": "all", "calories_per_100g": 387, "protein_per_100g": 22.0, "carbs_per_100g": 58.0, "fats_per_100g": 6.0, "fiber_per_100g": 10.0, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.9, "is_hostel_friendly": True},
    {"name": "Dalia (Broken Wheat)", "name_hindi": "दलिया", "category": "breakfast_grain", "region": "north", "calories_per_100g": 342, "protein_per_100g": 12.0, "carbs_per_100g": 75.0, "fats_per_100g": 2.0, "fiber_per_100g": 7.0, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.5, "is_hostel_friendly": True},
    {"name": "Rice (Idli/Dosa)", "name_hindi": "इडली चावल", "category": "breakfast_grain", "region": "south", "calories_per_100g": 130, "protein_per_100g": 2.7, "carbs_per_100g": 28.0, "fats_per_100g": 0.3, "fiber_per_100g": 0.4, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.6, "is_hostel_friendly": True},

    # Eggs
    {"name": "Whole Egg", "name_hindi": "अंडा", "category": "egg", "region": "all", "calories_per_100g": 155, "protein_per_100g": 13.0, "carbs_per_100g": 1.1, "fats_per_100g": 11.0, "fiber_per_100g": 0.0, "is_vegetarian": False, "is_vegan": False, "avg_price_per_100g_inr": 1.5, "is_hostel_friendly": True},
    {"name": "Egg White", "name_hindi": "एग व्हाइट", "category": "egg", "region": "all", "calories_per_100g": 52, "protein_per_100g": 11.0, "carbs_per_100g": 0.7, "fats_per_100g": 0.2, "fiber_per_100g": 0.0, "is_vegetarian": False, "is_vegan": False, "avg_price_per_100g_inr": 1.2, "is_hostel_friendly": True},

    # Dairy
    {"name": "Paneer", "name_hindi": "पनीर", "category": "dairy", "region": "all", "calories_per_100g": 265, "protein_per_100g": 18.3, "carbs_per_100g": 1.2, "fats_per_100g": 20.8, "fiber_per_100g": 0.0, "is_vegetarian": True, "is_vegan": False, "avg_price_per_100g_inr": 4.0, "is_hostel_friendly": False},
    {"name": "Curd (Dahi)", "name_hindi": "दही", "category": "dairy", "region": "all", "calories_per_100g": 98, "protein_per_100g": 11.0, "carbs_per_100g": 3.4, "fats_per_100g": 4.3, "fiber_per_100g": 0.0, "is_vegetarian": True, "is_vegan": False, "avg_price_per_100g_inr": 0.8, "is_hostel_friendly": True},
    {"name": "Greek Yogurt", "name_hindi": "ग्रीक योगर्ट", "category": "dairy", "region": "all", "calories_per_100g": 59, "protein_per_100g": 10.0, "carbs_per_100g": 3.6, "fats_per_100g": 0.4, "fiber_per_100g": 0.0, "is_vegetarian": True, "is_vegan": False, "avg_price_per_100g_inr": 2.5, "is_hostel_friendly": True},
    {"name": "Milk (Full Fat)", "name_hindi": "दूध", "category": "dairy", "region": "all", "calories_per_100g": 61, "protein_per_100g": 3.2, "carbs_per_100g": 4.8, "fats_per_100g": 3.3, "fiber_per_100g": 0.0, "is_vegetarian": True, "is_vegan": False, "avg_price_per_100g_inr": 0.6, "is_hostel_friendly": True},

    # Fruits
    {"name": "Banana", "name_hindi": "केला", "category": "fruit", "region": "all", "calories_per_100g": 89, "protein_per_100g": 1.1, "carbs_per_100g": 23.0, "fats_per_100g": 0.3, "fiber_per_100g": 2.6, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.4, "is_hostel_friendly": True},
    {"name": "Apple", "name_hindi": "सेब", "category": "fruit", "region": "all", "calories_per_100g": 52, "protein_per_100g": 0.3, "carbs_per_100g": 14.0, "fats_per_100g": 0.2, "fiber_per_100g": 2.4, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 1.0, "is_hostel_friendly": True},
    {"name": "Papaya", "name_hindi": "पपीता", "category": "fruit", "region": "all", "calories_per_100g": 43, "protein_per_100g": 0.5, "carbs_per_100g": 11.0, "fats_per_100g": 0.3, "fiber_per_100g": 1.7, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.3, "is_hostel_friendly": True},

    # ═══════════════════════════════════════════
    # LUNCH / DINNER INGREDIENTS
    # ═══════════════════════════════════════════

    # Dals & Legumes
    {"name": "Moong Dal", "name_hindi": "मूंग दाल", "category": "dal", "region": "all", "calories_per_100g": 347, "protein_per_100g": 24.0, "carbs_per_100g": 59.0, "fats_per_100g": 1.2, "fiber_per_100g": 16.3, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 1.2, "is_hostel_friendly": True},
    {"name": "Masoor Dal", "name_hindi": "मसूर दाल", "category": "dal", "region": "all", "calories_per_100g": 353, "protein_per_100g": 25.8, "carbs_per_100g": 59.0, "fats_per_100g": 1.1, "fiber_per_100g": 10.9, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 1.0, "is_hostel_friendly": True},
    {"name": "Toor Dal", "name_hindi": "तूर दाल", "category": "dal", "region": "all", "calories_per_100g": 335, "protein_per_100g": 22.3, "carbs_per_100g": 56.0, "fats_per_100g": 1.5, "fiber_per_100g": 15.0, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 1.1, "is_hostel_friendly": True},
    {"name": "Chana Dal", "name_hindi": "चना दाल", "category": "dal", "region": "all", "calories_per_100g": 364, "protein_per_100g": 22.0, "carbs_per_100g": 60.0, "fats_per_100g": 5.0, "fiber_per_100g": 17.4, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.9, "is_hostel_friendly": True},
    {"name": "Rajma (Kidney Beans)", "name_hindi": "राजमा", "category": "dal", "region": "north", "calories_per_100g": 127, "protein_per_100g": 8.7, "carbs_per_100g": 22.8, "fats_per_100g": 0.5, "fiber_per_100g": 6.4, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 1.4, "is_hostel_friendly": True},
    {"name": "Kabuli Chana", "name_hindi": "काबुली चना", "category": "dal", "region": "all", "calories_per_100g": 164, "protein_per_100g": 8.9, "carbs_per_100g": 27.4, "fats_per_100g": 2.6, "fiber_per_100g": 7.6, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 1.3, "is_hostel_friendly": True},
    {"name": "Soya Chunks", "name_hindi": "सोया चंक्स", "category": "dal", "region": "all", "calories_per_100g": 345, "protein_per_100g": 52.0, "carbs_per_100g": 33.0, "fats_per_100g": 0.5, "fiber_per_100g": 13.0, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 1.0, "is_hostel_friendly": True},

    # Grains
    {"name": "White Rice (Cooked)", "name_hindi": "चावल", "category": "grain", "region": "all", "calories_per_100g": 130, "protein_per_100g": 2.7, "carbs_per_100g": 28.0, "fats_per_100g": 0.3, "fiber_per_100g": 0.4, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.6, "is_hostel_friendly": True},
    {"name": "Brown Rice (Cooked)", "name_hindi": "ब्राउन राइस", "category": "grain", "region": "all", "calories_per_100g": 112, "protein_per_100g": 2.6, "carbs_per_100g": 23.0, "fats_per_100g": 0.9, "fiber_per_100g": 1.8, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.9, "is_hostel_friendly": True},
    {"name": "Whole Wheat Roti", "name_hindi": "रोटी", "category": "grain", "region": "all", "calories_per_100g": 264, "protein_per_100g": 9.0, "carbs_per_100g": 52.0, "fats_per_100g": 3.5, "fiber_per_100g": 6.0, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.5, "is_hostel_friendly": True},
    {"name": "Sweet Potato (Boiled)", "name_hindi": "शकरकंद", "category": "grain", "region": "all", "calories_per_100g": 86, "protein_per_100g": 1.6, "carbs_per_100g": 20.0, "fats_per_100g": 0.1, "fiber_per_100g": 3.0, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.5, "is_hostel_friendly": True},

    # Proteins - Non Veg
    {"name": "Chicken Breast (Cooked)", "name_hindi": "चिकन", "category": "meat", "region": "all", "calories_per_100g": 165, "protein_per_100g": 31.0, "carbs_per_100g": 0.0, "fats_per_100g": 3.6, "fiber_per_100g": 0.0, "is_vegetarian": False, "is_vegan": False, "avg_price_per_100g_inr": 3.5, "is_hostel_friendly": False},
    {"name": "Egg Bhurji (2 eggs)", "name_hindi": "एग भुर्जी", "category": "egg_dish", "region": "all", "calories_per_100g": 175, "protein_per_100g": 14.0, "carbs_per_100g": 4.0, "fats_per_100g": 11.0, "fiber_per_100g": 0.5, "is_vegetarian": False, "is_vegan": False, "avg_price_per_100g_inr": 1.8, "is_hostel_friendly": True},
    {"name": "Boiled Eggs", "name_hindi": "उबले अंडे", "category": "egg_dish", "region": "all", "calories_per_100g": 155, "protein_per_100g": 13.0, "carbs_per_100g": 1.1, "fats_per_100g": 11.0, "fiber_per_100g": 0.0, "is_vegetarian": False, "is_vegan": False, "avg_price_per_100g_inr": 1.5, "is_hostel_friendly": True},

    # Vegetables
    {"name": "Mixed Sabzi", "name_hindi": "मिक्स सब्ज़ी", "category": "vegetable", "region": "all", "calories_per_100g": 45, "protein_per_100g": 2.0, "carbs_per_100g": 8.0, "fats_per_100g": 1.0, "fiber_per_100g": 2.5, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.5, "is_hostel_friendly": False},
    {"name": "Spinach (Palak)", "name_hindi": "पालक", "category": "vegetable", "region": "all", "calories_per_100g": 23, "protein_per_100g": 2.9, "carbs_per_100g": 3.6, "fats_per_100g": 0.4, "fiber_per_100g": 2.2, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.3, "is_hostel_friendly": False},
    {"name": "Broccoli", "name_hindi": "ब्रोकली", "category": "vegetable", "region": "all", "calories_per_100g": 34, "protein_per_100g": 2.8, "carbs_per_100g": 7.0, "fats_per_100g": 0.4, "fiber_per_100g": 2.6, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.8, "is_hostel_friendly": False},
    {"name": "Sambar", "name_hindi": "सांभर", "category": "vegetable", "region": "south", "calories_per_100g": 50, "protein_per_100g": 3.0, "carbs_per_100g": 7.0, "fats_per_100g": 1.5, "fiber_per_100g": 2.0, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.4, "is_hostel_friendly": True},

    # ═══════════════════════════════════════════
    # SNACKS
    # ═══════════════════════════════════════════
    {"name": "Peanuts (Roasted)", "name_hindi": "मूंगफली", "category": "snack", "region": "all", "calories_per_100g": 567, "protein_per_100g": 25.8, "carbs_per_100g": 16.0, "fats_per_100g": 49.0, "fiber_per_100g": 8.5, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 1.0, "is_hostel_friendly": True},
    {"name": "Peanut Butter", "name_hindi": "पीनट बटर", "category": "snack", "region": "all", "calories_per_100g": 588, "protein_per_100g": 25.0, "carbs_per_100g": 20.0, "fats_per_100g": 50.0, "fiber_per_100g": 6.0, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 3.0, "is_hostel_friendly": True},
    {"name": "Almonds", "name_hindi": "बादाम", "category": "snack", "region": "all", "calories_per_100g": 579, "protein_per_100g": 21.0, "carbs_per_100g": 22.0, "fats_per_100g": 50.0, "fiber_per_100g": 12.5, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 7.0, "is_hostel_friendly": True},
    {"name": "Makhana (Fox Nuts)", "name_hindi": "मखाना", "category": "snack", "region": "all", "calories_per_100g": 347, "protein_per_100g": 9.7, "carbs_per_100g": 76.9, "fats_per_100g": 0.1, "fiber_per_100g": 14.5, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 5.0, "is_hostel_friendly": True},
    {"name": "Chana Chaat", "name_hindi": "चना चाट", "category": "snack", "region": "all", "calories_per_100g": 150, "protein_per_100g": 8.0, "carbs_per_100g": 25.0, "fats_per_100g": 2.5, "fiber_per_100g": 7.0, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 1.2, "is_hostel_friendly": True},
    {"name": "Whey Protein", "name_hindi": "व्हे प्रोटीन", "category": "supplement", "region": "all", "calories_per_100g": 370, "protein_per_100g": 80.0, "carbs_per_100g": 6.0, "fats_per_100g": 5.0, "fiber_per_100g": 0.0, "is_vegetarian": True, "is_vegan": False, "avg_price_per_100g_inr": 8.0, "is_hostel_friendly": True},
    {"name": "Sprouts (Mixed)", "name_hindi": "अंकुरित दाल", "category": "snack", "region": "all", "calories_per_100g": 99, "protein_per_100g": 9.0, "carbs_per_100g": 17.0, "fats_per_100g": 0.6, "fiber_per_100g": 4.5, "is_vegetarian": True, "is_vegan": True, "avg_price_per_100g_inr": 0.5, "is_hostel_friendly": True},
]

def seed():
    db = SessionLocal()
    try:
        existing = db.query(FoodItem).count()
        if existing > 0:
            print(f"✅ Food items already seeded ({existing} found), skipping.")
            return
        for food in foods:
            db.add(FoodItem(**food))
        db.commit()
        print(f"✅ Seeded {len(foods)} food items!")
    finally:
        db.close()

if __name__ == "__main__":
    seed()