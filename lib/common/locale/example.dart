const example = {
  "date": "2025-12-01",
  "user": { // /user/detail 接口返回
    "user_id": "123456",
    "gender": "male",
    "age": 27,
    "lang": 'en_US',
    "unitType":0,//0为公制，1为英制
    "height": 170,
    "weight_today": 63.2,
    "weight_yesterday": 63.6,
    "targetType":1,//0为减重，1为维持当前，2为增重
    "activityFactor":1.2,//活动因子
    // "allergies": ["peanut", "shrimp"]  
    "targetWeight": 60,
  },
  "goals": {
    "type": "fat_loss",
    "target_weight": 60,
    "daily_calorie_target": 1800,
    "daily_protein_target": 120,
    "daily_carb_target": 180,
    "daily_fat_target": 50
  },
  "nutrition_today": {
    "calories": 1220,
    "protein": 42,
    "carbs": 188,
    "fat": 36,
    "fiber": 9,
    "sugar": 42,
    "sodium": 890
  },
  "meals": [
    {
      "type": "breakfast",
      "time": "08:30",
      "items": [
        {
          "name": "鸡蛋",
          "amount": "2个",
          "calories": 140,
          "protein": 12,
          "carbs": 1,
          "fat": 10,
          "sugar": 0,
          "confidence": 0.96,
          "image_url": "https://xxx"
        }
      ]
    }
  ],
  "activity": {
    "steps": 6348,
    "calories_burned": 220,
    "exercise_minutes": 28,
    "workouts": [
      {
        "type": "running",
        "duration_min": 25,
        "calories": 180,
        "distance_km": 3.1
      }
    ]
  },
  "daily_trends": {
    "protein_deficit": true,
    "high_sugar_intake": true,
    "late_night_eating": false,
    "carb_ratio_high": false,
    "fat_ratio_high": false,
    "weight_increase_today": false
  },
  "habit_profile": {
    "usual_breakfast_time": "08:00-10:00",
    "likes_sweet_food": true,
    "low_protein_habit": true,
    "preferred_foods": ["鸡蛋", "牛奶"]
  },
  "historical_stats": {
    "avg_daily_calories": 1750,
    "avg_daily_protein": 62,
    "avg_daily_steps": 8120,
    "weight_change_7_days": -0.8
  },
  "system_flags": {
    "safe_mode": true,
    "language": "zh-cn",
    "timezone": "+08:00",
    "ai_version": "v1"
  }
};
