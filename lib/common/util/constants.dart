import 'dart:ui';
import 'package:calorie/common/icon/index.dart';
import 'package:get/get.dart';

// List mealOptions = [{'value':1,'label':"BREAKFAST".tr,'icon':AliIcon.breakfast,'color':const Color.fromARGB(255, 38, 225, 44)}, {'value':2,'label':"LUNCH".tr,'icon':AliIcon.lunch,'color':const Color.fromARGB(255, 255, 134, 73)},
//     {'value':3,'label':"DINNER".tr,'icon':AliIcon.supper,'color':const Color.fromARGB(255, 52, 157, 255)},{'value':4,'label':"SNACK".tr,'icon':AliIcon.extra,'color':const Color.fromARGB(255, 255, 80, 147)}];
    

List<Map<String, dynamic>> mealOptions() {
  return [
    {
      'value': 1,
      'label': "BREAKFAST".tr,
      'icon': AliIcon.breakfast,
      'color': const Color.fromARGB(255, 38, 225, 44)
    },
    {
      'value': 2,
      'label': "LUNCH".tr,
      'icon': AliIcon.lunch,
      'color': const Color.fromARGB(255, 255, 134, 73)
    },
    {
      'value': 3,
      'label': "DINNER".tr,
      'icon': AliIcon.supper,
      'color': const Color.fromARGB(255, 52, 157, 255)
    },
    {
      'value': 4,
      'label': "SNACK".tr,
      'icon': AliIcon.extra,
      'color': const Color.fromARGB(255, 255, 80, 147)
    },
  ];
}
final Map<int, Map<String, dynamic>> mealInfoMap = {
  for (var item in mealOptions())
    item['value'] as int: {
      'label': item['label'],
      'icon': item['icon'],
      'color': item['color'],
    }
};

Map<String, Map<String, String>> nutritionLabelMap() {
  return {
    "calorie": {
      "label": "CALORIE".tr,
      "unit": "KCAL".tr,
      "unitTranslate": "KCAL_UNIT".tr,
      "desc": "CALORIE_DESC".tr,
      "benefits": "CALORIE_BENEFITS".tr,
      "risks": "CALORIE_RISKS".tr,
      "sources": "CALORIE_SOURCES".tr
    },
    "carbs": {
      "label": "CARBOHYDRATE".tr,
      "unit": "G".tr,
      "unitTranslate": "G_UNIT".tr,
      "desc": "CARBOHYDRATE_DESC".tr,
      "benefits": "CARBOHYDRATE_BENEFITS".tr,
      "risks": "CARBOHYDRATE_RISKS".tr,
      "sources": "CARBOHYDRATE_SOURCES".tr
    },
    "fat": {
      "label": "FAT".tr,
      "unit": "G".tr,
      "unitTranslate": "G_UNIT".tr,
      "desc": "FAT_DESC".tr,
      "benefits": "FAT_BENEFITS".tr,
      "risks": "FAT_RISKS".tr,
      "sources": "FAT_SOURCES".tr
    },
    "protein": {
      "label": "PROTEIN".tr,
      "unit": "G".tr,
      "unitTranslate": "G_UNIT".tr,
      "desc": "PROTEIN_DESC".tr,
      "benefits": "PROTEIN_BENEFITS".tr,
      "risks": "PROTEIN_RISKS".tr,
      "sources": "PROTEIN_SOURCES".tr
    },
    "sugars": {
      "label": "SUGARS".tr,
      "unit": "G".tr,
      "unitTranslate": "G_UNIT".tr,
      "desc": "SUGARS_DESC".tr,
      "benefits": "SUGARS_BENEFITS".tr,
      "risks": "SUGARS_RISKS".tr,
      "sources": "SUGARS_SOURCES".tr
    },
    "dietaryFiber": {
      "label": "DIETARYFIBER".tr,
      "unit": "G".tr,
      "unitTranslate": "G_UNIT".tr,
      "desc": "DIETARYFIBER_DESC".tr,
      "benefits": "DIETARYFIBER_BENEFITS".tr,
      "risks": "DIETARYFIBER_RISKS".tr,
      "sources": "DIETARYFIBER_SOURCES".tr
    },
    "vitaminA": {
      "label": "VITAMINA".tr,
      "unit": "UG".tr,
      "unitTranslate": "UG_UNIT".tr,
      "desc": "VITAMINA_DESC".tr,
      "benefits": "VITAMINA_BENEFITS".tr,
      "risks": "VITAMINA_RISKS".tr,
      "sources": "VITAMINA_SOURCES".tr
    },
    "vitaminB1": {
      "label": "VITAMINB1".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "VITAMINB1_DESC".tr,
      "benefits": "VITAMINB1_BENEFITS".tr,
      "risks": "VITAMINB1_RISKS".tr,
      "sources": "VITAMINB1_SOURCES".tr
    },
    "vitaminB2": {
      "label": "VITAMINB2".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "VITAMINB2_DESC".tr,
      "benefits": "VITAMINB2_BENEFITS".tr,
      "risks": "VITAMINB2_RISKS".tr,
      "sources": "VITAMINB2_SOURCES".tr
    },
    "vitaminB3": {
      "label": "VITAMINB3".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "VITAMINB3_DESC".tr,
      "benefits": "VITAMINB3_BENEFITS".tr,
      "risks": "VITAMINB3_RISKS".tr,
      "sources": "VITAMINB3_SOURCES".tr
    },
    "vitaminB5": {
      "label": "VITAMINB5".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "VITAMINB5_DESC".tr,
      "benefits": "VITAMINB5_BENEFITS".tr,
      "risks": "VITAMINB5_RISKS".tr,
      "sources": "VITAMINB5_SOURCES".tr
    },
    "vitaminB6": {
      "label": "VITAMINB6".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "VITAMINB6_DESC".tr,
      "benefits": "VITAMINB6_BENEFITS".tr,
      "risks": "VITAMINB6_RISKS".tr,
      "sources": "VITAMINB6_SOURCES".tr
    },
    "vitaminB7": {
      "label": "VITAMINB7".tr,
      "unit": "UG".tr,
      "unitTranslate": "UG_UNIT".tr,
      "desc": "VITAMINB7_DESC".tr,
      "benefits": "VITAMINB7_BENEFITS".tr,
      "risks": "VITAMINB7_RISKS".tr,
      "sources": "VITAMINB7_SOURCES".tr
    },
    "vitaminB9": {
      "label": "VITAMINB9".tr,
      "unit": "UG".tr,
      "unitTranslate": "UG_UNIT".tr,
      "desc": "VITAMINB9_DESC".tr,
      "benefits": "VITAMINB9_BENEFITS".tr,
      "risks": "VITAMINB9_RISKS".tr,
      "sources": "VITAMINB9_SOURCES".tr
    },
    "vitaminB12": {
      "label": "VITAMINB12".tr,
      "unit": "UG".tr,
      "unitTranslate": "UG_UNIT".tr,
      "desc": "VITAMINB12_DESC".tr,
      "benefits": "VITAMINB12_BENEFITS".tr,
      "risks": "VITAMINB12_RISKS".tr,
      "sources": "VITAMINB12_SOURCES".tr
    },
    "vitaminC": {
      "label": "VITAMINC".tr,
      "unit": "MG".tr,
      "unitTranslate": "UG_UNIT".tr,
      "desc": "VITAMINC_DESC".tr,
      "benefits": "VITAMINC_BENEFITS".tr,
      "risks": "VITAMINC_RISKS".tr,
      "sources": "VITAMINC_SOURCES".tr
    },
    "vitaminD": {
      "label": "VITAMIND".tr,
      "unit": "UG".tr,
      "unitTranslate": "UG_UNIT".tr,
      "desc": "VITAMIND_DESC".tr,
      "benefits": "VITAMIND_BENEFITS".tr,
      "risks": "VITAMIND_RISKS".tr,
      "sources": "VITAMIND_SOURCES".tr
    },
    "vitaminE": {
      "label": "VITAMINE".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "VITAMINE_DESC".tr,
      "benefits": "VITAMINE_BENEFITS".tr,
      "risks": "VITAMINE_RISKS".tr,
      "sources": "VITAMINE_SOURCES".tr
    },
    "vitaminK": {
      "label": "VITAMINK".tr,
      "unit": "UG".tr,
      "unitTranslate": "UG_UNIT".tr,
      "desc": "VITAMINK_DESC".tr,
      "benefits": "VITAMINK_BENEFITS".tr,
      "risks": "VITAMINK_RISKS".tr,
      "sources": "VITAMINK_SOURCES".tr
    },
    "sodium": {
      "label": "SODIUM".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "SODIUM_DESC".tr,
      "benefits": "SODIUM_BENEFITS".tr,
      "risks": "SODIUM_RISKS".tr,
      "sources": "SODIUM_SOURCES".tr
    },
    "potassium": {
      "label": "POTASSIUM".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "POTASSIUM_DESC".tr,
      "benefits": "POTASSIUM_BENEFITS".tr,
      "risks": "POTASSIUM_RISKS".tr,
      "sources": "POTASSIUM_SOURCES".tr
    },
    "calcium": {
      "label": "CALCIUM".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "CALCIUM_DESC".tr,
      "benefits": "CALCIUM_BENEFITS".tr,
      "risks": "CALCIUM_RISKS".tr,
      "sources": "CALCIUM_SOURCES".tr
    },
    "magnesium": {
      "label": "MAGNESIUM".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "MAGNESIUM_DESC".tr,
      "benefits": "MAGNESIUM_BENEFITS".tr,
      "risks": "MAGNESIUM_RISKS".tr,
      "sources": "MAGNESIUM_SOURCES".tr
    },
    "iron": {
      "label": "IRON".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "IRON_DESC".tr,
      "benefits": "IRON_BENEFITS".tr,
      "risks": "IRON_RISKS".tr,
      "sources": "IRON_SOURCES".tr
    },
    "zinc": {
      "label": "ZINC".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "ZINC_DESC".tr,
      "benefits": "ZINC_BENEFITS".tr,
      "risks": "ZINC_RISKS".tr,
      "sources": "ZINC_SOURCES".tr
    },
    "copper": {
      "label": "COPPER".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "COPPER_DESC".tr,
      "benefits": "COPPER_BENEFITS".tr,
      "risks": "COPPER_RISKS".tr,
      "sources": "COPPER_SOURCES".tr
    },
    "phosphorus": {
      "label": "PHOSPHORUS".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "PHOSPHORUS_DESC".tr,
      "benefits": "PHOSPHORUS_BENEFITS".tr,
      "risks": "PHOSPHORUS_RISKS".tr,
      "sources": "PHOSPHORUS_SOURCES".tr
    },
    "selenium": {
      "label": "SELENIUM".tr,
      "unit": "UG".tr,
      "unitTranslate": "UG_UNIT".tr,
      "desc": "SELENIUM_DESC".tr,
      "benefits": "SELENIUM_BENEFITS".tr,
      "risks": "SELENIUM_RISKS".tr,
      "sources": "SELENIUM_SOURCES".tr
    },
    "manganese": {
      "label": "MANGANESE".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "MANGANESE_DESC".tr,
      "benefits": "MANGANESE_BENEFITS".tr,
      "risks": "MANGANESE_RISKS".tr,
      "sources": "MANGANESE_SOURCES".tr
    },
    "chloride": {
      "label": "CHLORIDE".tr,
      "unit": "MG".tr,
      "unitTranslate": "MG_UNIT".tr,
      "desc": "CHLORIDE_DESC".tr,
      "benefits": "CHLORIDE_BENEFITS".tr,
      "risks": "CHLORIDE_RISKS".tr,
      "sources": "CHLORIDE_SOURCES".tr
    },
    "iodine": {
      "label": "IODINE".tr,
      "unit": "UG".tr,
      "unitTranslate": "UG_UNIT".tr,
      "desc": "IODINE_DESC".tr,
      "benefits": "IODINE_BENEFITS".tr,
      "risks": "IODINE_RISKS".tr,
      "sources": "IODINE_SOURCES".tr
    },
  };
}


  List weightList = [
    '0-1',
    '1-2',
    '2-4',
    '3-5',
    '4-6',
    '5-8'
  ];