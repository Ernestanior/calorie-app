import 'package:flutter/material.dart';
import 'result.dart';

/// 历史记录详情页
/// 专门用于从历史记录跳转，直接展示已有数据，不需要API调用
class RecipeDetailFromHistoryPage extends StatelessWidget {
  final Map<String, dynamic> recipeData; // responseDto
  final List<String> ingredients;
  final String cuisineName;
  final int cuisineId;
  final String customPrompt;
  final List<Map<String, dynamic>> selectedIngredients;

  const RecipeDetailFromHistoryPage({
    super.key,
    required this.recipeData,
    required this.ingredients,
    required this.cuisineName,
    required this.cuisineId,
    required this.customPrompt,
    required this.selectedIngredients,
  });

  @override
  Widget build(BuildContext context) {
    // 直接使用 result.dart 的 RecipeDetailPage，传入 initialRecipe
    // 这样所有的展示逻辑都复用，只需要维护 result.dart
    return RecipeDetailPage(
      ingredients: ingredients,
      cuisineId: cuisineId,
      cuisineName: cuisineName,
      customPrompt: customPrompt,
      selectedIngredients: selectedIngredients,
      initialRecipe: recipeData, // 传入已有的数据，result.dart 会直接使用，不调用API
    );
  }
}

