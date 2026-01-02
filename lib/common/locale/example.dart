const example = {
  "date": "2025-12-01",
  "user": { // /user/detail 接口返回
    "userId": "123456",
    // "allergies": ["peanut", "shrimp"]  
  "age": 18,
  "gender": 1,
  "lang": "en_US",
  "height": 175,
  "dailyCalories": 1980,
  "dailyCarbs": 248,
  "dailyFats": 66,
  "dailyProtein": 105,
  "dailySugar": 0,
  "dailyFiber": 0,
  "activityFactor": 1.2,
  "targetType": 1,
  "initWeight": 70,
      "weight_today": 63.2,
    "weight_yesterday": 63.6,
  "targetWeight": 60,
  "weeklyWeightChange": 0,
  "targetStep": 8000,
  "unitType": 0,//0为公制，1为英制
  },
  "nutrition_today": { // /detection/count-by-date 传今日日期
    "calories": 1220,
    "protein": 42,
    "carbs": 188,
    "fat": 36,
    "fiber": 9,
    "sugar": 42,
    "sodium": 890
  },
  "meals": [// /detection/page 传今日日期
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
        }
      ]
    }
  ],

  "habit_profile": {
    "usual_breakfast_time": "08:00-10:00",
    "likes_sweet_food": true,
    "low_protein_habit": true,
    "preferred_foods": ["鸡蛋", "牛奶"]
  },
};
